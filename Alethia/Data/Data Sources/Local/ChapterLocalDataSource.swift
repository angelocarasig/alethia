//
//  ChapterLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import GRDB
import ZIPFoundation

final class ChapterLocalDataSource {
    init() { }
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double, override: Bool) throws -> Void {
        // Don't update if:
        // 1. Chapter is already completed (progress = 1.0), OR
        // 2. New progress is less than current progress
        // Unless explicitly overriding
        guard override || (chapter.progress < 1.0 && newProgress >= chapter.progress) else {
            return
        }
        
        try DatabaseProvider.shared.writer.write { db in
            guard var targetChapter = try Chapter.fetchOne(db, key: chapter.id) else {
                throw ChapterError.notFound
            }
            
            targetChapter.progress = newProgress
            try targetChapter.update(db)
            
            try updateMangaLastRead(db: db, for: targetChapter)
        }
    }
    
    // To be called on load next chapter
    func markChapterRead(chapter: Chapter) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            guard var targetChapter = try Chapter.fetchOne(db, key: chapter.id) else {
                throw ChapterError.notFound
            }
            
            targetChapter.progress = 1.0
            try targetChapter.update(db)
            
            try updateMangaLastRead(db: db, for: targetChapter)
        }
    }
    
    func markAllChapters(chapters: [Chapter], asRead: Bool) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            for chapter in chapters {
                var updatedChapter = chapter
                
                updatedChapter.progress = asRead ? 1.0 : 0.0
                
                try updatedChapter.update(db)
            }
        }
    }
    
    func getChapterContentsWithFallback(
        chapter: Chapter,
        fallbackToRemote: () async throws -> [String]
    ) async throws -> [String] {
        // Get fresh chapter data from database
        guard let chapterId = chapter.id else {
            throw ChapterError.notFound
        }
        
        let currentChapter = try await DatabaseProvider.shared.reader.read { db in
            guard let chapter = try Chapter.fetchOne(db, key: chapterId) else {
                throw ChapterError.notFound
            }
            return chapter
        }
        
        // Check if downloaded
        guard currentChapter.downloaded else {
            return try await fallbackToRemote()
        }
        
        // Try local retrieval
        do {
            return try getChapterContents(chapter: currentChapter)
        } catch {
            // Fallback to remote on local failure
            print("Local chapter retrieval failed: \(error). Falling back to remote...")
            return try await fallbackToRemote()
        }
    }
    
    private func getChapterContents(chapter: Chapter) throws -> [String] {
        guard let localPath = chapter.localPath else {
            throw ChapterError.notDownloaded
        }
        
        let cbzURL = URL(fileURLWithPath: localPath)
        
        guard FileManager.default.fileExists(atPath: cbzURL.path) else {
            throw ChapterError.fileNotFound
        }
        
        /// Temp directory should be fine - it should be removed automatically after
        /// a while anyway, which is what's intended
        let tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cbz-\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(
            at: tempDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let archive = try Archive(url: cbzURL, accessMode: .read)
        
        var extractedFiles: [(filename: String, url: URL)] = []
        
        for entry in archive {
            let fileName = entry.path
            let lowercased = fileName.lowercased()
            
            guard lowercased.hasSuffix(".jpg") ||
                    lowercased.hasSuffix(".jpeg") ||
                    lowercased.hasSuffix(".png") ||
                    lowercased.hasSuffix(".webp") else {
                continue
            }
            
            guard !fileName.contains("ComicInfo.xml") &&
                    !fileName.hasPrefix(".") else {
                continue
            }
            
            let cleanFileName = (fileName as NSString).lastPathComponent
            let destinationURL = tempDirectoryURL.appendingPathComponent(cleanFileName)
            
            _ = try archive.extract(entry, to: destinationURL)
            extractedFiles.append((filename: cleanFileName, url: destinationURL))
        }
        
        extractedFiles.sort { file1, file2 in
            return file1.filename.localizedStandardCompare(file2.filename) == .orderedAscending
        }
        
        let pageURLs = extractedFiles.map { $0.url.absoluteString }
        
        guard !pageURLs.isEmpty else {
            try? FileManager.default.removeItem(at: tempDirectoryURL)
            throw ChapterError.noContent
        }
        
        return pageURLs
    }
}

// MARK: - General helpers
private extension ChapterLocalDataSource {
    private func updateMangaLastRead(db: Database, for targetChapter: Chapter) throws -> Void {
        guard let origin = try Origin.fetchOne(db, key: targetChapter.originId) else {
            throw OriginError.notFound
        }
        
        guard var correlatingManga = try Manga.fetchOne(db, key: origin.mangaId) else {
            throw MangaError.notFound
        }
        
        print("Updating \(correlatingManga.title) last read to: \(Date().description)")
        
        correlatingManga.lastReadAt = Date()
        try correlatingManga.update(db)
    }
}

// MARK: - Download functionalities
extension ChapterLocalDataSource {
    func updateChapterLocalPath(chapter: Chapter, localPath: String) throws {
        try DatabaseProvider.shared.writer.write { db in
            // Update the chapter's localPath
            var updatedChapter = chapter
            updatedChapter.localPath = localPath
            
            try updatedChapter.update(db)
        }
    }
    
    func removeChapterDownload(chapter: Chapter) throws {
        guard let localPath = chapter.localPath else {
            throw ChapterError.notDownloaded
        }
        
        let fileManager = FileManager.default
        let cbzURL = URL(fileURLWithPath: localPath)
        
        if fileManager.fileExists(atPath: cbzURL.path) {
            do {
                try fileManager.removeItem(at: cbzURL)
            } catch {
                throw DownloadError.unknown(error)
            }
        }
        
        let parentDirectory = cbzURL.deletingLastPathComponent()
        if fileManager.fileExists(atPath: parentDirectory.path) {
            do {
                try fileManager.removeItem(at: parentDirectory)
            } catch {
                print("Failed to remove chapter directory: \(error)")
            }
        }
        
        try DatabaseProvider.shared.writer.write { db in
            guard var targetChapter = try Chapter.fetchOne(db, key: chapter.id) else {
                throw ChapterError.notFound
            }
            
            targetChapter.localPath = nil
            try targetChapter.update(db)
        }
        
        // NOTE: If it was recently downloaded it would be in queue - we need to remove it
        QueueProvider.shared.operations.removeValue(forKey: chapter.queueOperationId)
    }
    
    func removeAllChapterDownloads(for mangaId: Int64) throws {
        let chapters = try DatabaseProvider.shared.reader.read { db in
            try Chapter
                .joining(required: Chapter.origin.filter(Origin.Columns.mangaId == mangaId))
                .filter(Chapter.Columns.localPath != nil)
                .fetchAll(db)
        }
        
        guard !chapters.isEmpty else {
            return
        }
        
        let fileManager = FileManager.default
        var successfullyDeletedChapterIds: [Int64] = []
        var failedDeletions: [(chapter: Chapter, error: Error)] = []
        
        // First pass: Try to delete files and track successes/failures
        for chapter in chapters {
            guard let localPath = chapter.localPath,
                  let chapterId = chapter.id else { continue }
            
            let cbzURL = URL(fileURLWithPath: localPath)
            var deletionSuccessful = true
            
            // Try to delete the CBZ file
            if fileManager.fileExists(atPath: cbzURL.path) {
                do {
                    try fileManager.removeItem(at: cbzURL)
                } catch {
                    deletionSuccessful = false
                    failedDeletions.append((chapter: chapter, error: error))
                }
            }
            
            // Only try to delete parent directory if CBZ deletion was successful
            if deletionSuccessful {
                let parentDirectory = cbzURL.deletingLastPathComponent()
                if fileManager.fileExists(atPath: parentDirectory.path) {
                    // Don't care if this fails - it might contain other files
                    try? fileManager.removeItem(at: parentDirectory)
                }
                
                successfullyDeletedChapterIds.append(chapterId)
                
                QueueProvider.shared.operations.removeValue(forKey: chapter.queueOperationId)
            }
        }
        
        // Second pass: Update database only for successfully deleted files
        if !successfullyDeletedChapterIds.isEmpty {
            try DatabaseProvider.shared.writer.write { db in
                for chapterId in successfullyDeletedChapterIds {
                    guard var targetChapter = try Chapter.fetchOne(db, key: chapterId) else {
                        continue
                    }
                    
                    targetChapter.localPath = nil
                    try targetChapter.update(db)
                }
            }
        }
        
        // Report failures if any occurred
        if !failedDeletions.isEmpty {
            throw ApplicationError.batchDeletionError(
                successCount: successfullyDeletedChapterIds.count,
                failures: failedDeletions
            )
        }
    }
}

extension ChapterLocalDataSource {
    func getCBZMetadata(for chapter: Chapter, with pageCount: Int) throws -> CBZMetadata {
        try DatabaseProvider.shared.reader.read { db in
            // Get origin from chapter
            guard let origin = try Origin.filter(id: chapter.originId).fetchOne(db) else {
                throw OriginError.notFound
            }
            
            // Get manga from origin
            guard let manga = try Manga.filter(id: origin.mangaId).fetchOne(db) else {
                throw MangaError.notFound
            }
            
            // Get scanlator
            guard let scanlator = try Scanlator.filter(id: chapter.scanlatorId).fetchOne(db) else {
                throw ScanlatorError.notFound
            }
            
            // Get authors through the many-to-many relationship
            let authors = try manga.authors.fetchAll(db)
            let authorNames = authors.map { $0.name }
            
            // Get tags through the many-to-many relationship
            let tags = try manga.tags.fetchAll(db)
            let tagNames = tags.map { $0.name }
            
            return CBZMetadata(
                chapterNumber: chapter.number,
                chapterTitle: chapter.title,
                pageCount: pageCount,
                seriesTitle: manga.title,
                mangaSummary: manga.synopsis,
                authors: authorNames,
                tags: tagNames,
                scanlatorName: scanlator.name
            )
        }
    }
}

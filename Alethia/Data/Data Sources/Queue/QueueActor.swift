//
//  QueueActor.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation
import ZIPFoundation

actor QueueActor {}

// MARK: - Download Chapter
extension QueueActor {
    func downloadChapter(
        chapter: Chapter,
        remote: ChapterRemoteDataSource,
        local: ChapterLocalDataSource,
        continuation: AsyncStream<QueueOperationState>.Continuation
    ) async {
        do {
            // Step 1: Prepare location in filesystem
            let chapterFolder: URL = try prepareChapterDirectory(for: chapter)
            continuation.yield(.ongoing(0.1))
            
            // Step 2: Get chapter contents from remote
            let pages: [String] = try await remote.getChapterContents(chapter: chapter)
            
            guard !pages.isEmpty else {
                throw ChapterError.noContent
            }
            continuation.yield(.ongoing(0.15))
            
            // Step 3: Download contents async
            // index - page number
            // data - page data
            let downloadedPages: [(index: Int, data: Data)] = try await downloadPages(pages, to: chapterFolder) { progress in
                continuation.yield(.ongoing(progress))
            }
            
            // Step 4: Wait for everything to finish (already handled by TaskGroup)
            continuation.yield(.ongoing(0.9))
            
            // Step 5: Zip contents to .cbz
            let metadata: CBZMetadata = try local.getCBZMetadata(for: chapter, with: downloadedPages.count)
            
            // Step 5.5: Place .cbz in designated location
            let cbzPath = try await createCBZ(from: downloadedPages, for: chapter, metadata: metadata, in: chapterFolder)
            continuation.yield(.ongoing(0.95))
            
            // Step 6: Update local path for chapter to the location of the .cbz's prepared location
            try local.updateChapterLocalPath(chapter: chapter, localPath: cbzPath.path)
            continuation.yield(.ongoing(1.0))
            
            continuation.yield(.completed)
        } catch {
            continuation.yield(.failed(error))
        }
    }
    
    private func prepareChapterDirectory(for chapter: Chapter) throws -> URL {
        guard let chapterId = chapter.id else {
            throw ChapterError.notFound
        }
        
        let chapterFolder = Constants.Paths.DownloadsPath
            .appendingPathComponent("chapter-\(chapterId)", isDirectory: true)
        
        let fileManager = FileManager.default
        
        do {
            if !fileManager.fileExists(atPath: chapterFolder.path) {
                try fileManager.createDirectory(
                    at: chapterFolder,
                    withIntermediateDirectories: true
                )
            }
        } catch CocoaError.fileWriteNoPermission {
            throw DownloadError.noWritePermission
        } catch CocoaError.fileWriteOutOfSpace {
            throw DownloadError.insufficientStorage
        } catch {
            print("Failed to create directory: \(error)")
            throw DownloadError.unknown(error)
        }
        
        return chapterFolder
    }
    
    private func downloadPages( _ pageUrls: [String], to directory: URL, onProgress: @escaping (Double) -> Void) async throws -> [(index: Int, data: Data)] {
        var downloadedPages: [(index: Int, data: Data)] = []
        let totalPages = pageUrls.count
        var completedCount = 0
        
        try await withThrowingTaskGroup(of: (Int, Data).self) { group in
            // Add download tasks for each page
            for (index, pageUrl) in pageUrls.enumerated() {
                group.addTask {
                    // Download the page
                    guard let url = URL(string: pageUrl) else {
                        throw DownloadError.invalidUrl(pageUrl)
                    }
                    
                    let (data, _) = try await URLSession.shared.data(from: url)
                    return (index, data)
                }
            }
            
            // Collect results as they complete
            for try await (index, data) in group {
                downloadedPages.append((index: index, data: data))
                completedCount += 1
                
                // Calculate progress - from 15% to 90% completion
                let progress = 0.15 + (0.75 * Double(completedCount) / Double(totalPages))
                onProgress(progress)
            }
        }
        
        // Sort by index to maintain page order
        downloadedPages.sort { $0.index < $1.index }
        
        return downloadedPages
    }
    
    private func createCBZ(from pages: [(index: Int, data: Data)], for chapter: Chapter, metadata: CBZMetadata, in directory: URL) async throws -> URL {
        guard let chapterId = chapter.id else {
            throw ChapterError.notFound
        }
        
        let cbzPath = directory.appendingPathComponent("chapter-\(chapterId).cbz")
        print("Saving file to path: \(cbzPath.absoluteString)")
        
        // Create archive
        let archive = try Archive(url: cbzPath, accessMode: .create)
        
        let comicInfoXML = createComicInfoXML(from: metadata)
        let xmlData = comicInfoXML.data(using: .utf8)!
        
        try archive.addEntry(
            with: "ComicInfo.xml",
            type: .file,
            uncompressedSize: Int64(xmlData.count),
            provider: { position, size in
                let startIndex = Int(position)
                let endIndex = startIndex + Int(size)
                return xmlData.subdata(in: startIndex..<endIndex)
            }
        )
        
        // 2. Add page-data from memory
        for (index, data) in pages {
            let fileName = String(format: "%03d.jpg", index + 1)
            
            try archive.addEntry(
                with: fileName,
                type: .file,
                uncompressedSize: Int64(data.count),
                compressionMethod: .none, // No compression for images
                provider: { position, size in
                    let startIndex = Int(position)
                    let endIndex = startIndex + Int(size)
                    return data.subdata(in: startIndex..<endIndex)
                }
            )
        }
        
        return cbzPath
    }
    
    private func createComicInfoXML(from metadata: CBZMetadata) -> String {
        let authorsString = metadata.authors.joined(separator: ", ")
        let tagsString = metadata.tags.joined(separator: ", ")
        
        return """
        <?xml version="1.0" encoding="utf-8"?>
        <ComicInfo xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Title>\(metadata.chapterTitle.isEmpty ? "Chapter \(metadata.chapterNumber)" : metadata.chapterTitle)</Title>
            <Series>\(metadata.seriesTitle)</Series>
            <Number>\(metadata.chapterNumber)</Number>
            <PageCount>\(metadata.pageCount)</PageCount>
            <Summary>\(metadata.mangaSummary)</Summary>
            <Writer>\(authorsString)</Writer>
            <ScanInformation>\(metadata.scanlatorName)</ScanInformation>
            <Tags>\(tagsString)</Tags>
            <Manga>Yes</Manga>
        </ComicInfo>
        """
    }
}


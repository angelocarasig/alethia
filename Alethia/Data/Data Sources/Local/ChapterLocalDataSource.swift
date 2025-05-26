//
//  ChapterLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import GRDB

final class ChapterLocalDataSource {
    init() { }
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double, override: Bool) throws -> Void {
        // Don't update if chapter is already completed unless explicitly overriding
        guard override || chapter.progress < 1.0 else {
            return
        }
        
        try DatabaseProvider.shared.writer.write { db in
            guard var targetChapter = try Chapter.fetchOne(db, key: chapter.id) else {
                throw ChapterError.notFound
            }
            
            targetChapter.progress = newProgress
            try targetChapter.update(db)
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

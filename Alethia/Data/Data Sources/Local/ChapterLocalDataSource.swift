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

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
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double) throws -> Void {
        // If chapter progress is already 100% don't update it
        guard chapter.progress < 1.0 else { return }
        
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
}

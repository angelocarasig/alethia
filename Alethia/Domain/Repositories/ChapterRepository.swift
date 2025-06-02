//
//  ChapterRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import Foundation
import Combine

protocol ChapterRepository {
    func getChapterContents(chapter: Chapter, forceRemote: Bool) async throws -> [String]
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double, override: Bool) throws -> Void
    
    func markChapterRead(chapter: Chapter) throws -> Void
    
    // can be reused for all chapters above/below too
    func markAllChapters(chapters: [Chapter], asRead: Bool) throws -> Void
    
    func downloadChapter(chapter: Chapter) -> AsyncStream<QueueOperationState>
}

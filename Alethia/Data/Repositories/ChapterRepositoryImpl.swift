//
//  ChapterRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import UIKit.UIApplication

final class ChapterRepositoryImpl {
    private let local: ChapterLocalDataSource
    private let remote: ChapterRemoteDataSource
    private let actor: QueueActor
    
    init(local: ChapterLocalDataSource, remote: ChapterRemoteDataSource, actor: QueueActor) {
        self.local = local
        self.remote = remote
        self.actor = actor
    }
}

extension ChapterRepositoryImpl: ChapterRepository {    
    func getChapterContents(chapter: Chapter, forceRemote: Bool) async throws -> [String] {
        let shouldUseLocal = !forceRemote && chapter.downloaded
        
        return shouldUseLocal
        ? try local.getChapterContents(chapter: chapter)
        : try await remote.getChapterContents(chapter: chapter)
    }
    
    func markChapterRead(chapter: Chapter) throws {
        try local.markChapterRead(chapter: chapter)
    }
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double, override: Bool) throws {
        try local.updateChapterProgress(chapter: chapter, newProgress: newProgress, override: override)
    }
    
    func markAllChapters(chapters: [Chapter], asRead: Bool) throws {
        try local.markAllChapters(chapters: chapters, asRead: asRead)
    }
    
    func downloadChapter(chapter: Chapter) -> AsyncStream<QueueJobState> {
        /// 1. Prepare location in filesystem
        /// 2. Get chapter contents
        /// 3. Download contents async
        /// 4. Wait for everything to finish
        /// 5. Zip contents to .cbz
        /// 6. Place .cbz in prepared location
        AsyncStream { continuation in
            Task {
                let backgroundTask = await UIApplication.shared.beginBackgroundTask {
                    continuation.yield(.failure(DownloadError.backgroundTimeExpired))
                }
                
                await actor.downloadChapter(
                    chapter: chapter,
                    remote: remote,
                    local: local,
                    continuation: continuation
                )
                
                continuation.finish()
                
                await MainActor.run {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                }
            }
        }
    }
}

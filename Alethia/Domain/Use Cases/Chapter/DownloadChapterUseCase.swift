//
//  DownloadChapterUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

protocol DownloadChapterUseCase {
    func execute(chapter: Chapter) -> AsyncStream<QueueJobState>
}

final class DownloadChapterUseCaseImpl: DownloadChapterUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter) -> AsyncStream<QueueJobState> {
        return repository.downloadChapter(chapter: chapter)
    }
}

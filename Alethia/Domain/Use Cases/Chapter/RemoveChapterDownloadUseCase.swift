//
//  RemoveChapterDownloadUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/6/2025.
//

import Foundation

protocol RemoveChapterDownloadUseCase {
    func execute(chapter: Chapter) throws -> Void
}

final class RemoveChapterDownloadUseCaseImpl: RemoveChapterDownloadUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter) throws {
        try repository.removeChapterDownload(chapter: chapter)
    }
}

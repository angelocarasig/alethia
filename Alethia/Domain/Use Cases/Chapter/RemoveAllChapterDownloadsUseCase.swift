//
//  RemoveAllChapterDownloadsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/6/2025.
//

import Foundation

protocol RemoveAllChapterDownloadsUseCase {
    func execute(mangaId: Int64) throws -> Void
}

final class RemoveAllChapterDownloadsUseCaseImpl: RemoveAllChapterDownloadsUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64) throws {
        try repository.removeAllChapterDownloads(mangaId: mangaId)
    }
}

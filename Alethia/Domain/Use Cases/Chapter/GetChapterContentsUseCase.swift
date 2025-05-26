//
//  GetChapterContentsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import Foundation

protocol GetChapterContentsUseCase {
    func execute(chapter: Chapter, forceRemote: Bool) async throws -> [String]
}

extension GetChapterContentsUseCase {
    func execute(chapter: Chapter) async throws -> [String] {
        return try await execute(chapter: chapter, forceRemote: false)
    }
}

final class GetChapterContentsUseCaseImpl: GetChapterContentsUseCase {
    private var repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter, forceRemote: Bool) async throws -> [String] {
        return try await repository.getChapterContents(chapter: chapter, forceRemote: forceRemote)
    }
}

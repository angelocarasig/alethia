//
//  GetChapterContentsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import Foundation

protocol GetChapterContentsUseCase {
    func execute(chapter: Chapter) async throws -> [String]
}

final class GetChapterContentsUseCaseImpl: GetChapterContentsUseCase {
    private var repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter) async throws -> [String] {
        print("Executing content fetch for \(chapter.number)")
        return try await repository.getChapterContents(chapter: chapter)
    }
}

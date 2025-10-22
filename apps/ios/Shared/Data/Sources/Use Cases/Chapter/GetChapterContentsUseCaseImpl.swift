//
//  GetChapterContentsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation
import Domain

public final class GetChapterContentsUseCaseImpl: GetChapterContentsUseCase {
    private let repository: ChapterRepository
    
    public init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    public func execute(chapterId: Int64) async throws -> [String] {
        // validate chapter id
        guard chapterId > 0 else {
            throw BusinessError.invalidInput(reason: "Chapter ID must be positive")
        }
        
        return try await repository.getChapterContents(chapterId: chapterId)
    }
}

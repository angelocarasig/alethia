//
//  UpdateChapterProgressUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import Foundation

protocol UpdateChapterProgressUseCase {
    func execute(chapter: Chapter, newProgress: Double, override: Bool) throws -> Void
}

extension UpdateChapterProgressUseCase {
    func execute(chapter: Chapter, newProgress: Double) throws -> Void {
        try execute(chapter: chapter, newProgress: newProgress, override: false)
    }
}

final class UpdateChapterProgressUseCaseImpl: UpdateChapterProgressUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter, newProgress: Double, override: Bool) throws -> Void {
        try repository.updateChapterProgress(chapter: chapter, newProgress: newProgress, override: override)
    }
}

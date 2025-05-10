//
//  MarkChapterReadUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import Foundation

protocol MarkChapterReadUseCase {
    func execute(chapter: Chapter) throws -> Void
}

final class MarkChapterReadUseCaseImpl: MarkChapterReadUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapter: Chapter) throws -> Void {
        try repository.markChapterRead(chapter: chapter)
    }
}

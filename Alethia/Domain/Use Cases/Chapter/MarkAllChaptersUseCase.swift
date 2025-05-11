//
//  MarkAllChaptersUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

protocol MarkAllChaptersUseCase {
    func execute(chapters: [Chapter], asRead: Bool) throws -> Void
}

final class MarkAllChaptersUseCaseImpl: MarkAllChaptersUseCase {
    private let repository: ChapterRepository
    
    init(repository: ChapterRepository) {
        self.repository = repository
    }
    
    func execute(chapters: [Chapter], asRead: Bool) throws -> Void {
        try repository.markAllChapters(chapters: chapters, asRead: asRead)
    }
}

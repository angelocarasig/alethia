//
//  UpdateMangaSettingsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import Foundation

protocol UpdateMangaSettingsUseCase {
    func execute(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws -> Void
}

final class UpdateMangaSettingsUseCaseImpl: UpdateMangaSettingsUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(mangaId: Int64, showAllChapters: Bool?, showHalfChapters: Bool?) throws {
        try repository.updateMangaSettings(mangaId: mangaId, showAllChapters: showAllChapters, showHalfChapters: showHalfChapters)
    }
}

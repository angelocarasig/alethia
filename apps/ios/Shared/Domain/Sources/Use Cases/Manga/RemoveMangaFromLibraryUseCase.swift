//
//  RemoveMangaFromLibraryUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

public protocol RemoveMangaFromLibraryUseCase: Sendable {
    /// removes manga from library by manga id
    func execute(mangaId: Int64) async throws
}

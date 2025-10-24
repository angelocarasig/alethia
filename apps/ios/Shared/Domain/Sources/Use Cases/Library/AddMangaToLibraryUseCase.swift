//
//  AddMangaToLibraryUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

public protocol AddMangaToLibraryUseCase: Sendable {
    /// adds manga to library by manga id
    func execute(mangaId: Int64) async throws
}

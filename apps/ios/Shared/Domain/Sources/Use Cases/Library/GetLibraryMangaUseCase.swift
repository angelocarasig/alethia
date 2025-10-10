//
//  GetLibraryMangaUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 11/10/2025.
//

public protocol GetLibraryMangaUseCase: Sendable {
    func execute(query: LibraryQuery) -> AsyncStream<Result<LibraryQueryResult, Error>>
}

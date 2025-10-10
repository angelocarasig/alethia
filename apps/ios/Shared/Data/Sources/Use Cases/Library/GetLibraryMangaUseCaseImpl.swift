//
//  GetLibraryMangaUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain

public final class GetLibraryMangaUseCaseImpl: GetLibraryMangaUseCase {
    private let repository: LibraryRepository
    
    public init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    public func execute(query: LibraryQuery) -> AsyncStream<Result<LibraryQueryResult, Error>> {
        return repository.getLibraryManga(query: query)
    }
}

//
//  GetLibraryUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import Combine

protocol GetLibraryUseCase {
    func execute(filters: LibraryFilters) -> AnyPublisher<[Entry], Error>
}

final class GetLibraryUseCaseImpl: GetLibraryUseCase {
    private var repository: MangaRepository
    
    init (repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(filters: LibraryFilters) -> AnyPublisher<[Entry], any Error> {
        return repository.getLibrary(filters: filters)
    }
}

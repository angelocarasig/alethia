//
//  GetLibraryUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Combine

public protocol GetLibraryUseCase {
    func execute(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) -> AnyPublisher<[Domain.Models.Virtual.Entry], Error>
}

public final class GetLibraryUseCaseImpl: GetLibraryUseCase {
    private let repository: Domain.Repositories.MangaRepository
    
    init(repository: Domain.Repositories.MangaRepository) {
        self.repository = repository
    }
    
    public func execute(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) -> AnyPublisher<[Domain.Models.Virtual.Entry], Error> {
        return repository.getLibrary(filters: filters, collectionId: collectionId)
    }
}

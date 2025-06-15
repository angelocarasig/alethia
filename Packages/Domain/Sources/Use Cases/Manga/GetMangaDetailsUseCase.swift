//
//  GetMangaDetailsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Combine

public protocol GetMangaDetailsUseCase {
    func execute(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error>
}

public final class GetMangaDetailsUseCaseImpl: GetMangaDetailsUseCase {
    private let repository: Domain.Repositories.MangaRepository
    
    public init(repository: Domain.Repositories.MangaRepository) {
        self.repository = repository
    }
    
    public func execute(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
        return repository.getMangaDetails(entry: entry)
    }
}

//
//  SearchSourceUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import Foundation

protocol SearchSourceUseCase {
    func execute(source: Source, query: String, page: Int) async throws -> [Entry]
}

extension SearchSourceUseCase {
    func execute(source: Source, query: String) async throws -> [Entry] {
        return try await execute(source: source, query: query, page: 0)
    }
}

final class SearchSourceUseCaseImpl: SearchSourceUseCase {
    private let repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(source: Source, query: String, page: Int) async throws -> [Entry] {
        return try await repository.searchSource(source: source, query: query, page: page)
    }
}

//
//  GetSourceRouteContentUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

protocol GetSourceRouteContentUseCase {
    func execute(sourceRouteId: Int64, page: Int) async throws -> [Entry]
}

extension GetSourceRouteContentUseCase {
    func execute(sourceRouteId: Int64) async throws -> [Entry] {
        try await execute(sourceRouteId: sourceRouteId, page: 1)
    }
}

final class GetSourceRouteContentUseCaseImpl: GetSourceRouteContentUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(sourceRouteId: Int64, page: Int = 0) async throws -> [Entry] {
        return try await repository.getSourceRouteContent(sourceRouteId: sourceRouteId, page: page)
    }
}

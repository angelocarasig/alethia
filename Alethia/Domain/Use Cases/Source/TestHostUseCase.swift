//
//  TestHostUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

protocol TestHostUseCase {
    func execute(url: String) async throws -> NewHostPayload
}

final class TestHostUseCaseImpl: TestHostUseCase {
    private let repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(url: String) async throws -> NewHostPayload {
        return try await repository.testHostUseCase(url: url)
    }
}

//
//  CreateHostUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

protocol CreateHostUseCase {
    func execute(_ payload: NewHostPayload) async throws -> Void
}

final class CreateHostUseCaseImpl: CreateHostUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(_ payload: NewHostPayload) async throws -> Void {
        try await repository.createHost(payload: payload)
    }
}

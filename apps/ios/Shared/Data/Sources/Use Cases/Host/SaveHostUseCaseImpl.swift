//
//  SaveHostUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain

public final class SaveHostUseCaseImpl: SaveHostUseCase {
    private let repository: HostRepository
    
    public init(repository: HostRepository) {
        self.repository = repository
    }
    
    public func execute(_ dto: HostDTO, hostURL: URL) async throws -> Host {
        // validate host has at least one source
        guard !dto.sources.isEmpty else {
            throw BusinessError.noSourcesInHost
        }
        
        return try await repository.saveHost(dto, hostURL: hostURL)
    }
}

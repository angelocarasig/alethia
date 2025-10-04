//
//  GetAllHostsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class GetAllHostsUseCaseImpl: GetAllHostsUseCase {
    private let repository: HostRepository
    
    public init(repository: HostRepository) {
        self.repository = repository
    }
    
    public func execute() -> AsyncStream<[Domain.Host]> {
        return repository.getAllHosts()
    }
}

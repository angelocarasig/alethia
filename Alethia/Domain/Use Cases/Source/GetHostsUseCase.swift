//
//  GetHostsUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Foundation
import Combine

protocol GetHostsUseCase {
    func execute() -> AnyPublisher<[Host], Never>
}

final class GetHostsUseCaseImpl: GetHostsUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[Host], Never> {
        return repository.getHosts()
    }
}

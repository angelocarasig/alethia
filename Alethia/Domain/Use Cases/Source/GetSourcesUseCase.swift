//
//  GetSourcesUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import Combine

protocol GetSourcesUseCase {
    func execute() -> AnyPublisher<[Source], Never>
}

final class GetSourcesUseCaseImpl: GetSourcesUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[Source], Never> {
        return repository.getSources()
    }
}

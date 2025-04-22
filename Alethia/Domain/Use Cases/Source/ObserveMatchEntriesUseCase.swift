//
//  ObserveMatchEntriesUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import Combine

protocol ObserveMatchEntriesUseCase {
    func execute(entries: [Entry]) -> AnyPublisher<[Entry], Never>
}

final class ObserveMatchEntriesUseCaseImpl: ObserveMatchEntriesUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(entries: [Entry]) -> AnyPublisher<[Entry], Never> {
        return repository.observeMatchEntries(entries: entries)
    }
}

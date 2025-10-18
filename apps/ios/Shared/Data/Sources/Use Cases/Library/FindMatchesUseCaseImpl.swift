//
//  FindMatchesUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class FindMatchesUseCaseImpl: FindMatchesUseCase {
    private let repository: LibraryRepository
    
    public init(repository: LibraryRepository) {
        self.repository = repository
    }
    
    public func execute(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>> {
        return repository.findMatches(for: raw)
    }
}

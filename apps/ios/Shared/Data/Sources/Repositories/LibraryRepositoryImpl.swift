//
//  LibraryRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public final class LibraryRepositoryImpl: LibraryRepository {
    public init() {
    }
    
    public func findMatches(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>> {
        AsyncStream { continuation in
            // TODO: Implement find matches logic
            continuation.finish()
        }
    }
}

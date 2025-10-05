//
//  FindMatchesUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public protocol FindMatchesUseCase {
    /// Searches DB from a raw Entry domain entity input and outputs it enriched
    func execute(for raw: [Entry]) -> AsyncStream<[Entry]>
}

//
//  FindMatchesUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public protocol FindMatchesUseCase {
    func execute(for raw: [Entry]) -> AsyncStream<[Entry]>
}

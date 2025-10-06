//
//  FindMatchesUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public protocol FindMatchesUseCase: Sendable {
    func execute(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>>
}

//
//  GetAllHostsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public protocol GetAllHostsUseCase: Sendable {
    func execute() -> AsyncStream<[Host]>
}

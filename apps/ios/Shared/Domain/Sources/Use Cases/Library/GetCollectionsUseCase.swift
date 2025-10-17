//
//  GetCollectionsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 18/10/2025.
//

public protocol GetCollectionsUseCase {
    func execute() -> AsyncStream<Result<[Collection], Error>>
}

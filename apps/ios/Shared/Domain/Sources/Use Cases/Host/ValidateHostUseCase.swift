//
//  ValidateHostURLUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

public protocol ValidateHostURLUseCase: Sendable {
    func execute(url: URL) async throws -> HostDTO
}

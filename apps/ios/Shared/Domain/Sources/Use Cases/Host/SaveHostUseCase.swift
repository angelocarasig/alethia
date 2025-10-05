//
//  SaveHostUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

public protocol SaveHostUseCase: Sendable {
    @discardableResult
    func execute(_ dto: HostDTO, hostURL: URL) async throws -> Host
}

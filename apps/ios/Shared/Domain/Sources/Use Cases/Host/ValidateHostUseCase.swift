//
//  ValidateHostURLUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

/// Use case for validating a host URL and fetching its manifest
public protocol ValidateHostURLUseCase: Sendable {
    func execute(url: URL) async throws -> HostManifest
}

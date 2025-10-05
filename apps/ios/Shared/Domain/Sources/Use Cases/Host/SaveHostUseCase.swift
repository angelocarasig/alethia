//
//  SaveHostUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

/// Use case for saving a validated host from its manifest
public protocol SaveHostUseCase: Sendable {
    /// Saves a host manifest to the DB and optionally return the domain entity
    @discardableResult
    func execute(manifest: HostManifest, hostURL: URL) async throws -> Host
}

//
//  HostRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

public protocol HostRepository: Sendable {
    /// Validates a host URL and fetches its manifest
    func validateHost(url: URL) async throws -> HostManifest
    
    /// Saves a host from its manifest
    func saveHost(manifest: HostManifest, hostURL: URL) async throws -> Host
    
    /// Fetches all saved hosts
    func getAllHosts() -> AsyncStream<[Host]>
    
    /// Deletes a host by ID
    func deleteHost(id: Int64) async throws
}

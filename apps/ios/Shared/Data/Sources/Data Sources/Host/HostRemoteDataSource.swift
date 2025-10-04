//
//  HostRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain

/// Handles remote operations for host data
public final class HostRemoteDataSource: Sendable {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    func fetchManifest(from url: URL) async throws -> HostManifest {
        return try await networkService.request(url: url)
    }
}

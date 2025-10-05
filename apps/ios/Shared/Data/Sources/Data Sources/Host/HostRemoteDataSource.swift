//
//  HostRemoteDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain

public protocol HostRemoteDataSource: Sendable {
    func fetchManifest(from url: URL) async throws -> HostDTO
}

internal final class HostRemoteDataSourceImpl: HostRemoteDataSource {
    private let networkService: NetworkService
    
    init(networkService: NetworkService? = nil) {
        self.networkService = networkService ?? NetworkService()
    }
    
    func fetchManifest(from url: URL) async throws -> HostDTO {
        return try await networkService.request(url: url)
    }
}

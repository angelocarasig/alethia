//
//  SourcesRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import Combine

final class SourcesRepositoryImpl {
    private let local: SourceLocalDataSource
    private let remote: SourceRemoteDataSource
    
    init(local: SourceLocalDataSource, remote: SourceRemoteDataSource) {
        self.local = local
        self.remote = remote
    }
}

extension SourcesRepositoryImpl: SourcesRepository {
    func getHosts() -> AnyPublisher<[Host], Never> {
        return local.getHosts()
    }
    
    func getSources() -> AnyPublisher<[SourceMetadata], Never> {
        return local.getSources()
    }
    
    func testHostUseCase(url: String) async throws -> NewHostPayload {
        return try await remote.testHost(url: url)
    }
    
    func createHost(payload: NewHostPayload) async throws -> Void {
        try await local.createHost(with: payload)
    }
    
    func deleteHost(host: Host) throws {
        try local.deleteHost(host: host)
    }
    
    func toggleSourcePinned(sourceId: Int64, newValue: Bool) throws -> Void {
        try local.toggleSourcePinned(sourceId: sourceId, newValue: newValue)
    }
    
    func toggleSourceDisabled(sourceId: Int64, newValue: Bool) throws -> Void {
        try local.toggleSourceDisabled(sourceId: sourceId, newValue: newValue)
    }
    
    func searchSource(source: Source, query: String, page: Int) async throws -> [Entry] {
        return try await remote.searchSource(source: source, query: query, page: page)
    }
    
    func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Entry] {
        return try await remote.getSourceRouteContent(sourceRouteId: sourceRouteId, page: page)
    }
    
    func observeMatchEntries(entries: [Entry]) -> AnyPublisher<[Entry], Never> {
        return local.observeMatchEntries(entries: entries)
    }
}

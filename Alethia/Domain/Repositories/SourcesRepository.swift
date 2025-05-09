//
//  SourcesRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import Combine

protocol SourcesRepository {
    func getHosts() -> AnyPublisher<[Host], Never>
    
    func getSources() -> AnyPublisher<[Source], Never>
    
    func testHostUseCase(url: String) async throws -> NewHostPayload
    
    func createHost(payload: NewHostPayload) async throws -> Void
    
    func deleteHost(host: Host) throws -> Void
    
    func toggleSourcePinned(sourceId: Int64, newValue: Bool) throws -> Void
    
    func toggleSourceDisabled(sourceId: Int64, newValue: Bool) throws -> Void
    
    func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Entry]
    
    func observeMatchEntries(entries: [Entry]) -> AnyPublisher<[Entry], Never>
}

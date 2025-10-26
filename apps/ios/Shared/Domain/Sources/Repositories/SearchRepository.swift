//
//  SearchRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public protocol SearchRepository: Sendable {
    
    // MARK: Host Operations
    
    func fetch(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)?
    
    // MARK: Search Operations
    
    func search(sourceSlug: String, hostURL: URL, request: SearchRequestDTO) async throws -> SearchResponseDTO
    func search(sourceSlug: String, hostURL: URL, preset: SearchPreset, page: Int, limit: Int) async throws -> SearchResponseDTO
}

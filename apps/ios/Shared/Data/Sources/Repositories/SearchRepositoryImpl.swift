//
//  SearchRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import GRDB
import Domain

public final class SearchRepositoryImpl: SearchRepository {
    private let database: DatabaseConfiguration
    private let networkService: NetworkService
    
    public init() {
        self.database = DatabaseConfiguration.shared
        self.networkService = NetworkService()
    }
    
    // MARK: - Host Operations
    
    public func fetch(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // fetch source with its host relationship
        guard let sourceRecord = try SourceRecord
            .filter(SourceRecord.Columns.id == sourceId)
            .fetchOne(db) else {
            return nil
        }
        
        // fetch the host through the relationship
        guard let hostRecord = try sourceRecord.host.fetchOne(db) else {
            return nil
        }
        
        return (source: sourceRecord, host: hostRecord)
    }
    
    // MARK: - Search Operations
    
    public func search(sourceSlug: String, hostURL: URL, request: SearchRequestDTO) async throws -> SearchResponseDTO {
        let searchURL = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        do {
            return try await networkService.requestWithBody(url: searchURL, body: request)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
    
    public func search(sourceSlug: String, hostURL: URL, preset: SearchPreset, page: Int, limit: Int) async throws -> SearchResponseDTO {
        let searchURL = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent("search")
        
        let requestDTO = SearchRequestDTO(
            query: "",
            page: page,
            limit: limit,
            sort: preset.sortOption,
            direction: preset.sortDirection,
            filters: preset.filters
        )
        
        do {
            return try await networkService.requestWithBody(url: searchURL, body: requestDTO)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown))
        }
    }
}

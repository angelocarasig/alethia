//
//  SearchLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB

internal protocol SearchLocalDataSource: Sendable {
    func getHostForSource(_ sourceId: Int64) async throws -> Host?
}

internal final class SearchLocalDataSourceImpl: SearchLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getHostForSource(_ sourceId: Int64) async throws -> Host? {
        do {
            return try await database.reader.read { db in
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
                
                // map to domain entity
                guard let hostId = hostRecord.id else {
                    throw StorageError.recordNotFound(table: "host", id: String(sourceId))
                }
                
                // for search purposes, we only need basic host info
                // sources array can be empty since we're just using the host URL
                return Host(
                    id: hostId.rawValue,
                    name: hostRecord.name,
                    author: hostRecord.author,
                    url: hostRecord.url,
                    repository: hostRecord.repository,
                    official: hostRecord.official,
                    sources: []
                )
            }
        } catch let error as StorageError {
            throw error
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "getHostForSource")
        } catch {
            throw StorageError.queryFailed(sql: "getHostForSource", error: error)
        }
    }
}

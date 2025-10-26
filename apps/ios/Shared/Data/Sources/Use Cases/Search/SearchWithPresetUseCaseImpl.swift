//
//  SearchWithPresetUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import Domain
import GRDB

public final class SearchWithPresetUseCaseImpl: SearchWithPresetUseCase {
    private let repository: SearchRepository
    private let database: DatabaseConfiguration
    private let throttler: RequestThrottler
    
    public init(repository: SearchRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
        self.throttler = RequestThrottler.shared
    }
    
    public func execute(
        source: Source,
        preset: SearchPreset,
        page: Int,
        limit: Int
    ) async throws -> SearchQueryResult {
        // validate pagination parameters
        guard page > 0 else {
            throw BusinessError.invalidInput(reason: "Page must be greater than 0")
        }
        
        guard limit > 0 && limit <= Constants.Search.maxResults else {
            throw BusinessError.invalidInput(reason: "Limit must be between 1 and \(Constants.Search.maxResults)")
        }
        
        do {
            // fetch source and host from database
            let (sourceRecord, hostRecord) = try await database.reader.read { db in
                guard let result = try self.repository.fetch(sourceId: source.id, in: db) else {
                    throw BusinessError.resourceNotFound(type: "Source", identifier: String(source.id))
                }
                
                // cast to concrete types
                guard let sourceRecord = result.source as? SourceRecord else {
                    throw SystemError.mappingFailed(reason: "Invalid source record type")
                }
                
                guard let hostRecord = result.host as? HostRecord else {
                    throw SystemError.mappingFailed(reason: "Invalid host record type")
                }
                
                return (sourceRecord, hostRecord)
            }
            
            // throttle the request to prevent overwhelming the server
            let responseDTO = try await throttler.execute {
                try await self.repository.search(
                    sourceSlug: sourceRecord.slug,
                    hostURL: hostRecord.url,
                    preset: preset,
                    page: page,
                    limit: limit
                )
            }
            
            // map dto entries to domain entities
            let entries = responseDTO.results.map { dto in
                self.mapEntryDTOToDomain(dto, sourceId: source.id)
            }
            
            // create search result
            return SearchQueryResult(
                entries: entries,
                hasMore: responseDTO.more,
                currentPage: responseDTO.page,
                totalCount: nil
            )
            
        } catch is CancellationError {
            // convert swift concurrency cancellation to domain error
            throw DataAccessError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            // convert url session cancellation to domain error
            throw DataAccessError.cancelled
        } catch let error as NetworkError where error.isCancellation {
            // convert network cancellation to domain error
            throw DataAccessError.cancelled
        } catch let error as BusinessError {
            // propagate business errors as-is
            throw error
        } catch let error as SystemError {
            // propagate system errors as-is
            throw error
        } catch let error as NetworkError {
            // map network errors to domain errors
            throw error.toDomainError()
        } catch let error as StorageError {
            // map storage errors to domain errors
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            // map database errors to domain errors
            throw StorageError.from(grdbError: dbError, context: "searchWithPreset").toDomainError()
        } catch {
            // wrap unexpected errors
            throw DataAccessError.networkFailure(reason: "Failed to search with preset", underlying: error)
        }
    }
    
    // MARK: - Private Mapping
    
    private func mapEntryDTOToDomain(_ dto: EntryDTO, sourceId: Int64) -> Entry {
        Entry(
            mangaId: nil,
            sourceId: sourceId,
            slug: dto.slug,
            title: dto.title,
            cover: URL(string: dto.cover ?? "") ?? URL(fileURLWithPath: ""),
            state: .noMatch,
            unread: 0
        )
    }
}

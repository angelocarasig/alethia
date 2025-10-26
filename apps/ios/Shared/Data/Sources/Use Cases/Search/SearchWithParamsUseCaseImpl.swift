//
//  SearchWithParamsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 19/10/2025.
//

import Foundation
import Domain
import GRDB

public final class SearchWithParamsUseCaseImpl: SearchWithParamsUseCase {
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
        query: String,
        sort: Search.Options.Sort,
        direction: SortDirection,
        filters: [Search.Options.Filter: Search.Options.FilterValue]?,
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
        
        // validate query length
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.count > 200 {
            throw BusinessError.invalidInput(reason: "Search query is too long (max 200 characters)")
        }
        
        // build search request dto from parameters
        let request = SearchRequestDTO(
            query: trimmedQuery,
            page: page,
            limit: limit,
            sort: sort,
            direction: direction,
            filters: filters
        )
        
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
                
                // validate source is enabled
                if sourceRecord.disabled {
                    throw BusinessError.operationNotPermitted(reason: "Source '\(sourceRecord.name)' is disabled")
                }
                
                // validate filters are supported by this source
                if let filters = filters {
                    try self.validateFilters(filters, source: sourceRecord, db: db)
                }
                
                // validate sort is supported by this source
                try self.validateSort(sort, source: sourceRecord, db: db)
                
                return (sourceRecord, hostRecord)
            }
            
            // throttle the request to prevent overwhelming the server
            let responseDTO = try await throttler.execute {
                try await self.repository.search(
                    sourceSlug: sourceRecord.slug,
                    hostURL: hostRecord.url,
                    request: request
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
            throw StorageError.from(grdbError: dbError, context: "searchWithParams").toDomainError()
        } catch {
            // wrap unexpected errors
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
    
    // MARK: - Private Validation
    
    private func validateFilters(
        _ filters: [Search.Options.Filter: Search.Options.FilterValue],
        source: SourceRecord,
        db: Database
    ) throws {
        // fetch search config for this source
        guard let searchConfig = try SearchConfigRecord
            .filter(SearchConfigRecord.Columns.sourceId == source.id)
            .fetchOne(db) else {
            // no config means no filters supported
            if !filters.isEmpty {
                throw BusinessError.invalidInput(reason: "Source does not support search filters")
            }
            return
        }
        
        // check each filter is supported
        for (filter, _) in filters {
            if !searchConfig.supportedFilters.contains(filter) {
                throw BusinessError.invalidInput(
                    reason: "Filter '\(filter.displayName)' is not supported by this source"
                )
            }
        }
    }
    
    private func validateSort(
        _ sort: Search.Options.Sort,
        source: SourceRecord,
        db: Database
    ) throws {
        // fetch search config for this source
        guard let searchConfig = try SearchConfigRecord
            .filter(SearchConfigRecord.Columns.sourceId == source.id)
            .fetchOne(db) else {
            // no config means default sort only
            if sort != .relevance {
                throw BusinessError.invalidInput(reason: "Source only supports relevance sorting")
            }
            return
        }
        
        // check sort is supported
        if !searchConfig.supportedSorts.contains(sort) {
            throw BusinessError.invalidInput(
                reason: "Sort option '\(sort.displayName)' is not supported by this source"
            )
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

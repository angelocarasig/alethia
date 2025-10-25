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
    private let remote: SearchRemoteDataSource
    private let local: SearchLocalDataSource
    private let throttler: RequestThrottler
    
    public init() {
        self.remote = SearchRemoteDataSourceImpl()
        self.local = SearchLocalDataSourceImpl()
        self.throttler = RequestThrottler.shared
    }
    
    public func searchWithPreset(source: Source, preset: SearchPreset) async throws -> [Entry] {
        do {
            guard let host = try await local.getHostForSource(source.id) else {
                throw RepositoryError.hostNotFound
            }
            
            // throttle the remote request
            let responseDTO = try await throttler.execute {
                try await self.remote.searchWithPreset(
                    sourceSlug: source.slug,
                    host: host.url,
                    preset: preset
                )
            }
            
            // map dto to domain entities
            return responseDTO.results.map { dto in
                Entry(
                    mangaId: nil,
                    sourceId: source.id,
                    slug: dto.slug,
                    title: dto.title,
                    cover: URL(string: dto.cover ?? "")!,
                    state: .noMatch,
                    unread: 0
                )
            }
            
        } catch is CancellationError {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as NetworkError where error.isCancellation {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
    
    public func searchWithPreset(source: Source, preset: SearchPreset, page: Int, limit: Int) async throws -> SearchQueryResult {
        do {
            guard let host = try await local.getHostForSource(source.id) else {
                throw RepositoryError.hostNotFound
            }
            
            // throttle the remote request
            let responseDTO = try await throttler.execute {
                try await self.remote.searchWithPreset(
                    sourceSlug: source.slug,
                    host: host.url,
                    preset: preset,
                    page: page,
                    limit: limit
                )
            }
            
            // map dto to domain entities
            let entries = responseDTO.results.map { dto in
                Entry(
                    mangaId: nil,
                    sourceId: source.id,
                    slug: dto.slug,
                    title: dto.title,
                    cover: URL(string: dto.cover ?? "")!,
                    state: .noMatch,
                    unread: 0
                )
            }
            
            return SearchQueryResult(
                entries: entries,
                hasMore: responseDTO.more,
                currentPage: responseDTO.page,
                totalCount: nil
            )
            
        } catch is CancellationError {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as NetworkError where error.isCancellation {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
    
    public func search(source: Source, request: SearchRequestDTO) async throws -> SearchQueryResult {
        do {
            guard let host = try await local.getHostForSource(source.id) else {
                throw RepositoryError.hostNotFound
            }
            
            // throttle the remote request
            let responseDTO = try await throttler.execute {
                try await self.remote.search(
                    sourceSlug: source.slug,
                    host: host.url,
                    request: request
                )
            }
            
            // map dto to domain entities
            let entries = responseDTO.results.map { dto in
                Entry(
                    mangaId: nil,
                    sourceId: source.id,
                    slug: dto.slug,
                    title: dto.title,
                    cover: URL(string: dto.cover ?? "") ?? URL(fileURLWithPath: ""),
                    state: .noMatch,
                    unread: 0
                )
            }
            
            return SearchQueryResult(
                entries: entries,
                hasMore: responseDTO.more,
                currentPage: responseDTO.page,
                totalCount: nil
            )
            
        } catch is CancellationError {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let urlError as URLError where urlError.code == .cancelled {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as NetworkError where error.isCancellation {
            // convert to domain cancellation error
            throw DataAccessError.cancelled
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
}

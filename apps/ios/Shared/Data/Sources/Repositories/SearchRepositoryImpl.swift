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
    
    public init() {
        self.remote = SearchRemoteDataSourceImpl()
        self.local = SearchLocalDataSourceImpl()
    }
    
    public func searchWithPreset(source: Source, preset: SearchPreset) async throws -> [Entry] {
        do {
            guard let host = try await local.getHostForSource(source.id) else {
                throw RepositoryError.hostNotFound
            }
            
            let responseDTO = try await remote.searchWithPreset(
                sourceSlug: source.slug,
                host: host.url,
                preset: preset
            )
            
            // map dto to domain entities
            return responseDTO.results.map { dto in
                Entry(
                    mangaId: nil,
                    sourceId: source.id,
                    slug: dto.slug,
                    title: dto.title,
                    cover: URL(string: dto.cover ?? "")!,
                    state: .noMatch
                )
            }
            
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch let error as BusinessError {
            throw error
        } catch let error as DataAccessError {
            throw error
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
    
    private func search(source: Source, request: SearchRequestDTO) async throws -> [Entry] {
        do {
            guard let host = try await local.getHostForSource(source.id) else {
                throw RepositoryError.hostNotFound
            }
            
            let responseDTO = try await remote.search(
                sourceSlug: source.slug,
                host: host.url,
                request: request
            )
            
            // map dto to domain entities
            return responseDTO.results.map { dto in
                Entry(
                    mangaId: nil,
                    sourceId: source.id,
                    slug: dto.slug,
                    title: dto.title,
                    cover: URL(string: dto.cover ?? "")!,
                    state: .noMatch
                )
            }
            
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch let error as BusinessError {
            throw error
        } catch let error as DataAccessError {
            throw error
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to search", underlying: error)
        }
    }
}

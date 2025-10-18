//
//  LibraryLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 11/10/2025.
//

import Foundation
import Domain
import GRDB

internal protocol LibraryLocalDataSource: Sendable {
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>>
    func getLibraryCollections() -> AsyncStream<Result<[(CollectionRecord, Int)], Error>>
    func addMangaToLibrary(mangaId: Int64) async throws
    func removeMangaFromLibrary(mangaId: Int64) async throws
    func findMatches(for entries: [Entry]) -> AsyncStream<Result<[Entry], Error>>
}

internal struct LibraryDataBundle: Sendable {
    let entries: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)]
    let totalCount: Int
    let hasMore: Bool
}

internal final class LibraryLocalDataSourceImpl: LibraryLocalDataSource {
    let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getLibraryCollections() -> AsyncStream<Result<[(CollectionRecord, Int)], any Error>> {
        return AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> [(CollectionRecord, Int)] in
                let collections = try CollectionRecord
                    .order(CollectionRecord.Columns.name)
                    .fetchAll(db)
                
                return try collections.map { collection in
                    guard let collectionId = collection.id else {
                        throw StorageError.recordNotFound(table: "collection", id: "nil")
                    }
                    
                    let count = try MangaCollectionRecord
                        .filter(MangaCollectionRecord.Columns.collectionId == collectionId)
                        .fetchCount(db)
                    
                    return (collection, count)
                }
            }
            
            let task = Task {
                do {
                    for try await bundle in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(bundle))
                    }
                } catch let dbError as DatabaseError {
                    continuation.yield(.failure(StorageError.from(grdbError: dbError, context: "getLibraryCollections")))
                } catch let error as StorageError {
                    continuation.yield(.failure(error))
                } catch {
                    continuation.yield(.failure(StorageError.queryFailed(sql: "getLibraryCollections", error: error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func addMangaToLibrary(mangaId: Int64) async throws {
        do {
            try await database.writer.write { db in
                guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
                    throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
                }
                
                manga.inLibrary = true
                manga.addedAt = Date()
                try manga.update(db)
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "addMangaToLibrary")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "addMangaToLibrary", error: error)
        }
    }
    
    func removeMangaFromLibrary(mangaId: Int64) async throws {
        do {
            try await database.writer.write { db in
                guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
                    throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
                }
                
                manga.inLibrary = false
                manga.addedAt = .distantPast
                try manga.update(db)
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "removeMangaFromLibrary")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "removeMangaFromLibrary", error: error)
        }
    }
    
    func getLibraryEntries(query: LibraryQuery) -> AsyncStream<Result<LibraryDataBundle, Error>> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> LibraryDataBundle in
                guard let self else {
                    return LibraryDataBundle(entries: [], totalCount: 0, hasMore: false)
                }
                
                do {
                    var request = MangaRecord
                        .filter(MangaRecord.Columns.inLibrary)
                    
                    request = try self.applyFilters(request, filters: query.filters, db: db)
                    
                    // exclude entries with null dates when sorting by those dates
                    switch query.sort.field {
                    case .lastRead:
                        request = request.filter(MangaRecord.Columns.lastReadAt != nil)
                    case .lastUpdated:
                        request = request.filter(MangaRecord.Columns.updatedAt != nil)
                    case .dateAdded:
                        request = request.filter(MangaRecord.Columns.addedAt != nil)
                    default:
                        break
                    }
                    
                    let totalCount = try request.fetchCount(db)
                    request = self.applySorting(request, sort: query.sort)
                    
                    if let afterId = query.cursor?.afterId {
                        request = try self.applyKeysetPagination(request, afterId: afterId, sort: query.sort, db: db)
                    }
                    
                    // fetch limit+1 rows to determine if more exist
                    let limit = query.cursor?.limit ?? 50
                    let limited = request.limit(limit + 1)
                    
                    var tuples: [(manga: MangaRecord, cover: CoverRecord, unreadCount: Int, primaryOrigin: OriginRecord)] = []
                    tuples.reserveCapacity(min(limit, 64))
                    var count = 0
                    var sawExtra = false
                    
                    let cursor = try MangaRecord.fetchCursor(db, limited)
                    while let manga = try cursor.next() {
                        count += 1
                        if count <= limit {
                            guard let mangaId = manga.id?.rawValue else { continue }
                            
                            guard let cover = try manga.cover.fetchOne(db) ?? manga.covers.limit(1).fetchOne(db) else {
                                continue
                            }
                            guard let origin = try manga.origin.fetchOne(db) else {
                                continue
                            }
                            
                            let unread = try self.calculateUnreadCount(mangaId: mangaId, db: db)
                            
                            tuples.append((manga: manga, cover: cover, unreadCount: unread, primaryOrigin: origin))
                        } else {
                            sawExtra = true
                            break
                        }
                    }
                    
                    return LibraryDataBundle(entries: tuples, totalCount: totalCount, hasMore: sawExtra)
                    
                } catch let dbError as DatabaseError {
                    throw StorageError.from(grdbError: dbError, context: "getLibraryEntries")
                } catch let error as StorageError {
                    throw error
                } catch {
                    throw StorageError.queryFailed(sql: "getLibraryEntries", error: error)
                }
            }
            
            let task = Task {
                do {
                    for try await bundle in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(bundle))
                    }
                } catch let error as StorageError {
                    continuation.yield(.failure(error))
                } catch {
                    continuation.yield(.failure(StorageError.queryFailed(sql: "getLibraryEntries observation", error: error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

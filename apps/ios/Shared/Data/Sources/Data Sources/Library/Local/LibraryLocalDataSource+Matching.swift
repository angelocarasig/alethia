//
//  LibraryLocalDataSource+Matching.swift
//  Data
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import GRDB

// MARK: - Find Matches

extension LibraryLocalDataSourceImpl {
    func findMatches(for entries: [Entry]) async throws -> [Entry] {
        do {
            return try await database.reader.read { db in
                var enrichedEntries: [Entry] = []
                enrichedEntries.reserveCapacity(entries.count)
                
                for entry in entries {
                    let enriched = matchEntry(entry, in: db)
                    enrichedEntries.append(enriched)
                }
                
                return enrichedEntries
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "findMatches")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "findMatches", error: error)
        }
    }
    
    func matchEntry(_ entry: Entry, in db: Database) -> Entry {
        do {
            // step 1: try slug matching (highest priority)
            let slugMatches = try findBySlug(entry.slug, in: db)
            
            if slugMatches.count == 1 {
                let manga = slugMatches[0]
                guard let mangaId = manga.id else {
                    throw StorageError.recordNotFound(table: "manga", id: "nil after slug match")
                }
                
                let origins = try manga.origins.fetchAll(db)
                let hasSameSource = origins.contains { $0.sourceId?.rawValue == entry.sourceId }
                
                if hasSameSource {
                    return Entry(
                        mangaId: mangaId.rawValue,
                        sourceId: entry.sourceId,
                        slug: entry.slug,
                        title: entry.title,
                        cover: entry.cover,
                        state: .exactMatch,
                        unread: 0
                    )
                } else {
                    return Entry(
                        mangaId: mangaId.rawValue,
                        sourceId: entry.sourceId,
                        slug: entry.slug,
                        title: entry.title,
                        cover: entry.cover,
                        state: .crossSourceMatch,
                        unread: 0
                    )
                }
            } else if slugMatches.count > 1 {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .matchVerificationFailed,
                    unread: 0
                )
            }
            
            // step 2: try title matching (fallback)
            let titleMatches = try findByTitle(entry.title, in: db)
            
            if titleMatches.isEmpty {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .noMatch,
                    unread: 0
                )
            }
            
            // check which matches have same source
            var sameSourceMatches: [MangaRecord] = []
            for manga in titleMatches {
                let origins = try manga.origins.fetchAll(db)
                if origins.contains(where: { $0.sourceId?.rawValue == entry.sourceId }) {
                    sameSourceMatches.append(manga)
                }
            }
            
            if sameSourceMatches.count == 1 {
                guard let mangaId = sameSourceMatches[0].id else {
                    throw StorageError.recordNotFound(table: "manga", id: "nil after title match")
                }
                
                return Entry(
                    mangaId: mangaId.rawValue,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchSameSource,
                    unread: 0
                )
            } else if sameSourceMatches.count > 1 {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchSameSourceAmbiguous,
                    unread: 0
                )
            } else {
                return Entry(
                    mangaId: nil,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .titleMatchDifferentSource,
                    unread: 0
                )
            }
            
        } catch {
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .matchVerificationFailed,
                unread: 0
            )
        }
    }
    
    func findBySlug(_ slug: String, in db: Database) throws -> [MangaRecord] {
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            JOIN \(OriginRecord.databaseTableName) origin ON origin.mangaId = manga.id
            WHERE origin.slug = ?
              AND manga.inLibrary = 1
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [slug])
    }
    
    func findByTitle(_ title: String, in db: Database) throws -> [MangaRecord] {
        let sql = """
            SELECT DISTINCT manga.*
            FROM \(MangaRecord.databaseTableName) manga
            WHERE manga.inLibrary = 1
              AND manga.id IN (
                SELECT id as mangaId FROM \(MangaRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
                
                UNION
                
                SELECT mangaId FROM \(AlternativeTitleRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
            )
            """
        
        return try MangaRecord.fetchAll(db, sql: sql, arguments: [title, title])
    }
}

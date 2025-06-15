//
//  MangaLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain
import Combine
import GRDB

internal typealias MangaLocalDataSource = Data.DataSources.MangaLocalDataSource
private typealias Details = Domain.Models.Virtual.Details
private typealias Entry = Domain.Models.Virtual.Entry

public extension Data.DataSources {
    final class MangaLocalDataSource: Sendable {
        private let database: DatabaseWriter
        
        internal init(database: DatabaseWriter = DatabaseProvider.shared.writer) {
            self.database = database
        }
    }
}

// MARK: - Manga Details

internal extension MangaLocalDataSource {
    /// Fetches detailed manga information for the given entry.
    ///
    /// Searches by manga ID first for exact matches, then falls back to title matching.
    /// Returns all matching manga with their complete details including:
    /// - Metadata (titles, authors, covers, tags)
    /// - Organization (collections, origins)
    /// - Content (chapters filtered by user preferences)
    ///
    /// - Parameter entry: The entry to fetch details for
    /// - Returns: Publisher emitting arrays of matching manga details
    /// NOTE - we return an array in case of duplicate matches (i.e. two of same title but different content)
    /// when this occurs it would be resolved in presentation layer
    func getMangaDetails(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
        return ValueObservation.tracking { [weak self] db -> [Details] in
            guard let self = self else { return [] }
            
            // try id match first
            if let mangaId = entry.mangaId,
               let manga = try Domain.Models.Persistence.Manga.fetchOne(db, key: mangaId),
               let detail = try self.buildDetail(for: manga, db: db) {
                return [detail]
            }
            
            // fallback to title matching
            return try self.findByTitle(entry.title, db: db)
                .compactMap { manga in
                    try self.buildDetail(for: manga, db: db)
                }
        }
        .publisher(in: database, scheduling: .async(onQueue: .main))
        .eraseToAnyPublisher()
    }
}

private extension MangaLocalDataSource {
    func findByTitle(_ title: String, db: Database) throws -> [Domain.Models.Persistence.Manga] {
        // create search pattern
        guard let pattern = FTS5Pattern(matchingAllPrefixesIn: title) else {
            return []
        }
        
        var foundIds = Set<Int64>()
        var results: [Domain.Models.Persistence.Manga] = []
        
        // search main titles using FTS5
        let mainTitleIds = try Int64.fetchAll(
            db,
            sql: """
                SELECT rowid 
                FROM \(MangaTitleFTS5.databaseTableName) 
                WHERE \(MangaTitleFTS5.databaseTableName) MATCH ?
            """,
            arguments: [pattern]
        )
        
        // fetch manga for main title matches
        if !mainTitleIds.isEmpty {
            let mainMatches = try Domain.Models.Persistence.Manga
                .filter(mainTitleIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .fetchAll(db)
            
            for manga in mainMatches {
                if let id = manga.id {
                    results.append(manga)
                    foundIds.insert(id)
                }
            }
        }
        
        // search alternative titles using FTS5
        let altTitleMangaIds = try Int64.fetchAll(
            db,
            sql: """
                SELECT DISTINCT mangaId 
                FROM \(MangaAltTitleFTS5.databaseTableName) 
                WHERE \(MangaAltTitleFTS5.databaseTableName) MATCH ?
            """,
            arguments: [pattern]
        )
        
        // fetch manga for alt title matches (excluding already found)
        if !altTitleMangaIds.isEmpty {
            let altMatches = try Domain.Models.Persistence.Manga
                .filter(altTitleMangaIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .filter(!foundIds.contains(Domain.Models.Persistence.Manga.Columns.id))
                .fetchAll(db)
            
            for manga in altMatches {
                if let id = manga.id {
                    results.append(manga)
                }
            }
        }
        
        return results
    }
    
    func buildDetail(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> Details? {
        guard manga.id != nil else { return nil }
        
        // fetch all related data
        let titles = try manga.titles.fetchAll(db)
        let authors = try manga.authors.fetchAll(db)
        let covers = try manga.covers.fetchAll(db)
        let tags = try manga.tags.fetchAll(db)
        let collections = try manga.collections.fetchAll(db)
        
        // complex relations
        let sources = try buildSourceInfos(for: manga, db: db)
        let chapters = try buildChapterInfos(for: manga, db: db)
        
        return Details(
            manga: manga,
            titles: titles,
            authors: authors,
            covers: covers,
            tags: tags,
            collections: collections,
            sources: sources,
            chapters: chapters
        )
    }
    
    func buildSourceInfos(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> [Details.SourceInfo] {
        let origins = try manga.origins
            .order(Domain.Models.Persistence.Origin.Columns.priority.asc)
            .fetchAll(db)
        
        return try origins.map { origin in
            let source = try origin.source.fetchOne(db)
            let host = try source?.host.fetchOne(db)
            let scanlators = try buildScanlatorInfos(for: origin, db: db)
            
            return Details.SourceInfo(
                origin: origin,
                source: source,
                host: host,
                scanlators: scanlators
            )
        }
    }
    
    func buildScanlatorInfos(for origin: Domain.Models.Persistence.Origin, db: Database) throws -> [Details.ScanlatorInfo] {
        guard let originId = origin.id else { return [] }
        
        let channels = try Domain.Models.Persistence.Channel
            .filter(Domain.Models.Persistence.Channel.Columns.originId == originId)
            .order(Domain.Models.Persistence.Channel.Columns.priority.asc)
            .fetchAll(db)
        
        return try channels.compactMap { channel -> Details.ScanlatorInfo? in
            guard let scanlator = try Domain.Models.Persistence.Scanlator
                .fetchOne(db, key: channel.scanlatorId) else { return nil }
            
            return Details.ScanlatorInfo(
                scanlator: scanlator,
                priority: channel.priority
            )
        }
    }
    
    func buildChapterInfos(for manga: Domain.Models.Persistence.Manga, db: Database) throws -> [Details.ChapterInfo] {
        // using best chapters view to get unified list
        let chapters = try manga.chapters.fetchAll(db)
        
        return try chapters.compactMap { chapter -> Details.ChapterInfo? in
            guard
                let origin = try Domain.Models.Persistence.Origin.fetchOne(db, key: chapter.originId),
                let scanlator = try Domain.Models.Persistence.Scanlator.fetchOne(db, key: chapter.scanlatorId)
            else { return nil }
            
            let source = try origin.source.fetchOne(db)
            let host = try source?.host.fetchOne(db)
            
            return Details.ChapterInfo(
                chapter: chapter,
                scanlator: scanlator,
                origin: origin,
                source: source,
                host: host
            )
        }
    }
}

// MARK: - Library Operations
// TODO: Add library operations here

// MARK: - Metadata Updates
// TODO: Add cover, orientation, collection updates here

// MARK: - Priority Management
// TODO: Add origin and scanlator priority updates here

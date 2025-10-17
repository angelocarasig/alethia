//
//  MangaLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation
import Domain
import GRDB
import Core

// MARK: - Data Bundle for Repository

internal struct MangaDataBundle {
    let manga: MangaRecord
    let authors: [AuthorRecord]
    let tags: [TagRecord]
    let covers: [CoverRecord]
    let alternativeTitles: [AlternativeTitleRecord]
    let origins: [OriginRecord]
    let sources: [OriginRecord.ID: (source: SourceRecord, host: HostRecord)]
    let chapters: [ChapterWithMetadata]
    let collections: [(collection: CollectionRecord, count: Int)]
}

internal struct ChapterWithMetadata {
    let chapter: ChapterRecord
    let scanlatorName: String
    let sourceIcon: URL?
}

// MARK: - Helper DTOs for Row Mapping

private struct ChapterRow {
    let id: Int64
    let originId: Int64
    let scanlatorId: Int64
    let slug: String
    let title: String
    let number: Double
    let date: Date
    let url: String
    let language: String
    let progress: Double
    let lastReadAt: Date?
    let scanlatorName: String
    let sourceIcon: String?
    
    init?(row: Row) {
        guard let id = row[ChapterRecord.Columns.id.name] as Int64?,
              let originId = row[ChapterRecord.Columns.originId.name] as Int64?,
              let scanlatorId = row[ChapterRecord.Columns.scanlatorId.name] as Int64?,
              let slug = row[ChapterRecord.Columns.slug.name] as String?,
              let title = row[ChapterRecord.Columns.title.name] as String?,
              let number = row[ChapterRecord.Columns.number.name] as Double?,
              let date = row[ChapterRecord.Columns.date.name] as Date?,
              let url = row[ChapterRecord.Columns.url.name] as String?,
              let language = row[ChapterRecord.Columns.language.name] as String?,
              let progress = row[ChapterRecord.Columns.progress.name] as Double?,
              let scanlatorName = row["scanlatorName"] as String? else {
            return nil
        }
        
        self.id = id
        self.originId = originId
        self.scanlatorId = scanlatorId
        self.slug = slug
        self.title = title
        self.number = number
        self.date = date
        self.url = url
        self.language = language
        self.progress = progress
        self.lastReadAt = row[ChapterRecord.Columns.lastReadAt.name] as Date?
        self.scanlatorName = scanlatorName
        self.sourceIcon = row["sourceIcon"] as String?
    }
    
    func toChapterRecord() -> ChapterRecord {
        ChapterRecord(
            id: ChapterRecord.ID(rawValue: id),
            originId: OriginRecord.ID(rawValue: originId),
            scanlatorId: ScanlatorRecord.ID(rawValue: scanlatorId),
            slug: slug,
            title: title,
            number: number,
            date: date,
            url: URL(string: url)!,
            language: LanguageCode(language),
            progress: progress,
            lastReadAt: lastReadAt
        )
    }
    
    func toChapterWithMetadata() -> ChapterWithMetadata {
        ChapterWithMetadata(
            chapter: toChapterRecord(),
            scanlatorName: scanlatorName,
            sourceIcon: sourceIcon.flatMap(URL.init(string:))
        )
    }
}

// MARK: - Protocol

internal protocol MangaLocalDataSource: Sendable {
    func getAllManga(for entry: Entry) -> AsyncStream<[MangaDataBundle]>
    func getSourceAndHost(sourceId: Int64) async throws -> (source: SourceRecord, host: HostRecord)
    @discardableResult
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord
}

// MARK: - Implementation

internal final class MangaLocalDataSourceImpl: MangaLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getAllManga(for entry: Entry) -> AsyncStream<[MangaDataBundle]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> [MangaDataBundle] in
                guard let self = self else { return [] }
                
                do {
                    let mangaIds = try self.findMangaIds(for: entry, in: db)
                    guard !mangaIds.isEmpty else { return [] }
                    
                    return try self.fetchMangaBundles(for: mangaIds, in: db)
                } catch {
#if DEBUG
                    print("Error in getAllManga: \(error)")
#endif
                    return []
                }
            }
            
            let task = Task {
                do {
                    for try await mangaData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(mangaData)
                    }
                } catch {
#if DEBUG
                    print("Observation error: \(error)")
#endif
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func getSourceAndHost(sourceId: Int64) async throws -> (source: SourceRecord, host: HostRecord) {
        try await database.reader.read { db in
            guard let source = try SourceRecord.fetchOne(db, key: SourceRecord.ID(rawValue: sourceId)) else {
                throw RepositoryError.mappingError(reason: "Source not found")
            }
            
            guard let host = try source.host.fetchOne(db) else {
                throw RepositoryError.hostNotFound
            }
            
            return (source: source, host: host)
        }
    }
    
    @discardableResult
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord {
        try await database.writer.write { db in
            let mangaId = try self.findOrCreateManga(dto: dto, in: db)
            
            try self.batchInsertRelatedData(
                dto: dto,
                mangaId: mangaId,
                sourceId: sourceId,
                chapters: chapters,
                in: db
            )
            
            return try MangaRecord.fetchOne(db, key: mangaId)!
        }
    }
    
    // MARK: - Private Manga Fetching Methods
    
    // sanitize input for fts5 queries to avoid syntax errors
    private func sanitizeForFTS(_ query: String) -> String {
        // remove fts5 special characters that act as operators
        let specialChars = CharacterSet(charactersIn: "!\"^*()+-")
        return query.components(separatedBy: specialChars)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func findMangaIds(for entry: Entry, in db: Database) throws -> [Int64] {
        if let mangaId = entry.mangaId {
            return [mangaId]
        }
        
        // sanitize the title for fts5 to prevent syntax errors
        let sanitizedTitle = sanitizeForFTS(entry.title)
        
        // fallback to like query if sanitized title is empty
        guard !sanitizedTitle.isEmpty else {
            return try findMangaIdsWithLike(for: entry, in: db)
        }
        
        let sql = """
            SELECT DISTINCT mangaId FROM (
                -- search by origin slug
                SELECT mangaId FROM \(OriginRecord.databaseTableName)
                WHERE slug = ?
                
                UNION
                
                -- search by manga title using FTS
                SELECT rowid as mangaId FROM \(MangaTitleFTS5.databaseTableName)
                WHERE \(MangaTitleFTS5.databaseTableName) MATCH ?
                
                UNION
                
                -- search by alternative title using FTS
                SELECT mangaId FROM \(MangaAltTitleFTS5.databaseTableName)
                WHERE \(MangaAltTitleFTS5.databaseTableName) MATCH ?
            )
            """
        
        do {
            return try Int64.fetchAll(db, sql: sql, arguments: [entry.slug, sanitizedTitle, sanitizedTitle])
        } catch {
            // if fts still fails, fallback to like query
#if DEBUG
            print("FTS query failed, falling back to LIKE: \(error)")
#endif
            return try findMangaIdsWithLike(for: entry, in: db)
        }
    }
    
    // fallback method using like queries instead of fts
    private func findMangaIdsWithLike(for entry: Entry, in db: Database) throws -> [Int64] {
        let sql = """
            SELECT DISTINCT mangaId FROM (
                -- search by origin slug
                SELECT mangaId FROM \(OriginRecord.databaseTableName)
                WHERE slug = ?
                
                UNION
                
                -- search by manga title using LIKE
                SELECT id as mangaId FROM \(MangaRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
                
                UNION
                
                -- search by alternative title using LIKE
                SELECT mangaId FROM \(AlternativeTitleRecord.databaseTableName)
                WHERE title = ? COLLATE NOCASE
            )
            """
        
        return try Int64.fetchAll(db, sql: sql, arguments: [entry.slug, entry.title, entry.title])
    }
    
    private func fetchMangaBundles(for mangaIds: [Int64], in db: Database) throws -> [MangaDataBundle] {
        let mangaRecords = try MangaRecord
            .filter(mangaIds.contains(MangaRecord.Columns.id))
            .fetchAll(db)
        
        return try mangaRecords.compactMap { manga in
            guard let mangaId = manga.id else { return nil }
            return try fetchMangaBundle(for: manga, mangaId: mangaId, in: db)
        }
    }
    
    private func fetchMangaBundle(for manga: MangaRecord, mangaId: MangaRecord.ID, in db: Database) throws -> MangaDataBundle {
        let authors = try manga.authors.fetchAll(db)
        let tags = try manga.tags.fetchAll(db)
        let covers = try manga.covers.fetchAll(db)
        let alternativeTitles = try manga.alternativeTitles.fetchAll(db)
        let origins = try manga.origins.fetchAll(db)
        let sources = try fetchSourcesForOrigins(origins, in: db)
        let chapters = try fetchChaptersWithMetadata(for: manga, in: db)
        
        let collectionRecords = try manga.collections.fetchAll(db)
        let collectionsWithCounts = try collectionRecords.map { collection -> (CollectionRecord, Int) in
            guard let collectionId = collection.id else {
                throw RepositoryError.mappingError(reason: "collection id is nil")
            }
            
            let count = try MangaCollectionRecord
                .filter(MangaCollectionRecord.Columns.collectionId == collectionId)
                .fetchCount(db)
            
            return (collection, count)
        }
        
        return MangaDataBundle(
            manga: manga,
            authors: authors,
            tags: tags,
            covers: covers,
            alternativeTitles: alternativeTitles,
            origins: origins,
            sources: sources,
            chapters: chapters,
            collections: collectionsWithCounts
        )
    }
    
    private func fetchSourcesForOrigins(_ origins: [OriginRecord], in db: Database) throws -> [OriginRecord.ID: (source: SourceRecord, host: HostRecord)] {
        var sources: [OriginRecord.ID: (source: SourceRecord, host: HostRecord)] = [:]
        
        let sourceIds = origins.compactMap { $0.sourceId }
        guard !sourceIds.isEmpty else { return sources }
        
        let sourceRecords = try SourceRecord
            .filter(sourceIds.contains(SourceRecord.Columns.id))
            .including(required: SourceRecord.host)
            .fetchAll(db)
        
        for origin in origins {
            guard let originId = origin.id,
                  let sourceId = origin.sourceId,
                  let source = sourceRecords.first(where: { $0.id == sourceId }),
                  let host = try source.host.fetchOne(db) else { continue }
            
            sources[originId] = (source: source, host: host)
        }
        
        return sources
    }
    
    private func fetchChaptersWithMetadata(for manga: MangaRecord, in db: Database) throws -> [ChapterWithMetadata] {
        guard let mangaId = manga.id else { return [] }
        
        let sql = """
            SELECT 
                c.*,
                s.name as scanlatorName,
                src.icon as sourceIcon
            FROM \(BestChapterView.databaseTableName) bc
            JOIN \(ChapterRecord.databaseTableName) c ON c.id = bc.chapterId
            JOIN \(ScanlatorRecord.databaseTableName) s ON s.id = c.scanlatorId
            JOIN \(OriginRecord.databaseTableName) o ON o.id = c.originId
            LEFT JOIN \(SourceRecord.databaseTableName) src ON src.id = o.sourceId
            WHERE bc.mangaId = ?
              AND bc.rank = 1
              AND (\(manga.showAllChapters ? "1=1" : "bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER)"))
            ORDER BY bc.number ASC
            """
        
        let rows = try Row.fetchAll(db, sql: sql, arguments: [mangaId.rawValue])
        
        return rows.compactMap { row in
            ChapterRow(row: row)?.toChapterWithMetadata()
        }
    }
    
    // MARK: - Private Manga Saving Methods
    
    private func findOrCreateManga(dto: MangaDTO, in db: Database) throws -> MangaRecord.ID {
        if let existing = try MangaRecord
            .filter(MangaRecord.Columns.title == dto.title)
            .fetchOne(db),
           let id = existing.id {
            var updated = existing
            updated.updatedAt = dto.updatedAt
            updated.lastFetchedAt = Date()
            try updated.update(db)
            return id
        }
        
        var mangaRecord = MangaRecord(
            title: dto.title,
            synopsis: dto.synopsis
        )
        mangaRecord.updatedAt = dto.updatedAt
        mangaRecord.lastFetchedAt = Date()
        
        try mangaRecord.insert(db)
        
        guard let mangaId = mangaRecord.id else {
            throw RepositoryError.mappingError(reason: "Failed to get manga ID after insert")
        }
        
        return mangaId
    }
    
    private func batchInsertRelatedData(
        dto: MangaDTO,
        mangaId: MangaRecord.ID,
        sourceId: Int64,
        chapters: [ChapterDTO],
        in db: Database
    ) throws {
        try self.batchInsertAuthors(dto.authors, mangaId: mangaId, db: db)
        try self.batchInsertTags(dto.tags, mangaId: mangaId, db: db)
        try self.batchInsertCovers(dto.covers, mangaId: mangaId, db: db)
        try self.batchInsertAlternativeTitles(dto.alternativeTitles, mangaId: mangaId, db: db)
        
        let origin = try self.insertOrigin(dto, mangaId: mangaId, sourceId: sourceId, db: db)
        
        if let originId = origin.id {
            try self.batchInsertChapters(chapters, originId: originId, db: db)
        }
        
    }
    
    private func batchInsertAuthors(_ authorNames: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for name in authorNames {
            let author = try AuthorRecord.filter(AuthorRecord.Columns.name == name).fetchOne(db)
            ?? AuthorRecord(name: name)
            
            var mutableAuthor = author
            if mutableAuthor.id == nil {
                try mutableAuthor.insert(db)
            }
            
            if let authorId = mutableAuthor.id {
                var junction = MangaAuthorRecord(
                    mangaId: mangaId,
                    authorId: authorId
                )
                try junction.insert(db, onConflict: .ignore)
            }
        }
    }
    
    private func batchInsertTags(_ tagNames: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for tagName in tagNames {
            let normalizedName = tagName
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
            
            let tag = try TagRecord
                .filter(TagRecord.Columns.normalizedName == normalizedName)
                .fetchOne(db) ?? TagRecord(
                    normalizedName: normalizedName,
                    displayName: tagName,
                    canonicalId: nil
                )
            
            var mutableTag = tag
            if mutableTag.id == nil {
                try mutableTag.insert(db)
            }
            
            if let tagId = mutableTag.id {
                var junction = MangaTagRecord(
                    mangaId: mangaId,
                    tagId: tagId
                )
                try junction.insert(db, onConflict: .ignore)
            }
        }
    }
    
    private func batchInsertCovers(_ coverUrls: [String], mangaId: MangaRecord.ID, db: Database) throws {
        try CoverRecord
            .filter(CoverRecord.Columns.mangaId == mangaId)
            .deleteAll(db)
        
        for (index, coverURLString) in coverUrls.enumerated() {
            guard let coverURL = URL(string: coverURLString) else { continue }
            
            var coverRecord = CoverRecord(
                mangaId: mangaId,
                isPrimary: index == 0,
                localPath: coverURL,
                remotePath: coverURL
            )
            try coverRecord.insert(db)
        }
    }
    
    private func batchInsertAlternativeTitles(_ titles: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for title in titles {
            var altTitleRecord = AlternativeTitleRecord(
                mangaId: mangaId,
                title: title
            )
            try altTitleRecord.insert(db, onConflict: .ignore)
        }
    }
    
    private func insertOrigin(_ dto: MangaDTO, mangaId: MangaRecord.ID, sourceId: Int64, db: Database) throws -> OriginRecord {
        if let existing = try OriginRecord
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .filter(OriginRecord.Columns.sourceId == sourceId)
            .fetchOne(db) {
            return existing
        }
        
        let maxPriority = try OriginRecord
            .select(max(OriginRecord.Columns.priority))
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .asRequest(of: Int.self)
            .fetchOne(db)
        
        var origin = OriginRecord(
            mangaId: mangaId,
            sourceId: SourceRecord.ID(rawValue: sourceId),
            slug: dto.slug,
            url: dto.url,
            priority: maxPriority == nil ? 0 : maxPriority! + 1,
            classification: Classification(rawValue: dto.classification) ?? .Unknown,
            status: Status(rawValue: dto.publication) ?? .Unknown
        )
        
        try origin.insert(db)
        return origin
    }
    
    private func batchInsertChapters(_ chapters: [ChapterDTO], originId: OriginRecord.ID, db: Database) throws {
        let chaptersByScanlator = Dictionary(grouping: chapters) { $0.scanlator }
        
        let existingPriorities = try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .fetchAll(db)
        
        var maxPriority = existingPriorities.map(\.priority).max() ?? -1
        
        for (scanlatorName, chapterGroup) in chaptersByScanlator {
            let scanlator = try ScanlatorRecord
                .filter(ScanlatorRecord.Columns.name == scanlatorName)
                .fetchOne(db) ?? ScanlatorRecord(name: scanlatorName)
            
            var mutableScanlator = scanlator
            if mutableScanlator.id == nil {
                try mutableScanlator.insert(db)
            }
            
            guard let scanlatorId = mutableScanlator.id else { continue }
            
            if !existingPriorities.contains(where: { $0.scanlatorId == scanlatorId }) {
                maxPriority += 1
                var priority = OriginScanlatorPriorityRecord(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    priority: maxPriority
                )
                try priority.insert(db)
            }
            
            for chapterDTO in chapterGroup {
                var chapter = ChapterRecord(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    slug: chapterDTO.slug,
                    title: chapterDTO.title,
                    number: chapterDTO.number,
                    date: chapterDTO.date,
                    url: URL(string: chapterDTO.url)!,
                    language: LanguageCode(chapterDTO.language),
                    progress: 0,
                    lastReadAt: nil
                )
                try chapter.insert(db, onConflict: .ignore)
            }
        }
    }
}

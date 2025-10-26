//
//  MangaRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import Domain
import GRDB

public final class MangaRepositoryImpl: MangaRepository {
    private let database: DatabaseConfiguration
    private let networkService: NetworkService
    
    public init() {
        self.database = DatabaseConfiguration.shared
        self.networkService = NetworkService()
    }
    
    // MARK: - Remote Operations
    
    public func remoteFetchManga(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> MangaDTO {
        let url = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent(entrySlug)
        
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown)).toDomainError()
        }
    }
    
    public func remoteFetchChapters(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> [ChapterDTO] {
        let url = hostURL
            .appendingPathComponent(sourceSlug)
            .appendingPathComponent(entrySlug)
            .appendingPathComponent("chapters")
        
        do {
            return try await networkService.request(url: url)
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch {
            throw NetworkError.requestFailed(underlyingError: error as? URLError ?? URLError(.unknown)).toDomainError()
        }
    }
    
    // MARK: - Source Operations
    
    public func fetch(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard let source = try SourceRecord.fetchOne(db, key: SourceRecord.ID(rawValue: sourceId)) else {
            return nil
        }
        
        guard let host = try source.host.fetchOne(db) else {
            return nil
        }
        
        return (source: source, host: host)
    }
    
    // MARK: - Manga Operations
    
    public func fetch(mangaId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId))
    }
    
    public func fetch(bySlug slug: String, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try OriginRecord
            .filter(OriginRecord.Columns.slug == slug)
            .including(required: OriginRecord.manga)
            .asRequest(of: MangaRecord.self)
            .fetchAll(db)
    }
    
    public func fetch(byTitle title: String, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // try exact match first
        let exactMatches = try MangaRecord
            .filter(MangaRecord.Columns.title == title)
            .fetchAll(db)
        
        if !exactMatches.isEmpty {
            return exactMatches
        }
        
        // fallback to case-insensitive match
        return try MangaRecord
            .filter(sql: "LOWER(title) = LOWER(?)", arguments: [title])
            .fetchAll(db)
    }
    
    public func findOrCreate(title: String, synopsis: String, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        if let existing = try MangaRecord
            .filter(MangaRecord.Columns.title == title)
            .fetchOne(db) {
            return existing
        }
        
        var manga = MangaRecord(title: title, synopsis: synopsis)
        manga.updatedAt = Date()
        manga.lastFetchedAt = Date()
        try manga.insert(db)
        return manga
    }
    
    public func update(mangaId: Int64, updatedAt: Date, lastFetchedAt: Date, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
        }
        
        manga.updatedAt = updatedAt
        manga.lastFetchedAt = lastFetchedAt
        try manga.update(db)
    }
    
    public func update(mangaId: Int64, fields: MangaUpdateFields, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            throw StorageError.recordNotFound(table: "manga", id: String(mangaId))
        }
        
        if let inLibrary = fields.inLibrary {
            manga.inLibrary = inLibrary
            manga.addedAt = inLibrary ? .now : .distantPast
        }
        if let orientation = fields.orientation { manga.orientation = orientation }
        if let showAllChapters = fields.showAllChapters { manga.showAllChapters = showAllChapters }
        if let showHalfChapters = fields.showHalfChapters { manga.showHalfChapters = showHalfChapters }
        if let lastReadAt = fields.lastReadAt { manga.lastReadAt = lastReadAt }
        
        try manga.update(db)
    }
    
    // MARK: - Author Operations
    
    public func fetch(authorId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try AuthorRecord.fetchOne(db, key: AuthorRecord.ID(rawValue: authorId))
    }
    
    public func fetch(authorName: String, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try AuthorRecord.filter(AuthorRecord.Columns.name == authorName).fetchOne(db)
    }
    
    public func fetchAuthors(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard let manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            return []
        }
        
        return try manga.authors.fetchAll(db)
    }
    
    @discardableResult
    public func save(authorName: String, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        if let existing = try AuthorRecord
            .filter(AuthorRecord.Columns.name == authorName)
            .fetchOne(db) {
            return existing
        }
        
        var author = AuthorRecord(name: authorName)
        try author.insert(db)
        return author
    }
    
    public func save(mangaId: Int64, authorId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var junction = MangaAuthorRecord(
            mangaId: MangaRecord.ID(rawValue: mangaId),
            authorId: AuthorRecord.ID(rawValue: authorId)
        )
        try junction.insert(db, onConflict: .ignore)
    }
    
    public func deleteAuthors(mangaId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try MangaAuthorRecord
            .filter(MangaAuthorRecord.Columns.mangaId == mangaId)
            .deleteAll(db)
    }
    
    // MARK: - Author Bulk Operations
    
    @discardableResult
    public func saveAuthors(_ names: [String], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var authors: [AuthorRecord] = []
        for name in names {
            if let author = try save(authorName: name, in: db) as? AuthorRecord {
                authors.append(author)
            }
        }
        return authors
    }
    
    public func saveAuthors(mangaId: Int64, authorIds: [Int64], in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        for authorId in authorIds {
            try save(mangaId: mangaId, authorId: authorId, in: db)
        }
    }
    
    public func saveAuthors(mangaId: Int64, names: [String], in db: Any) throws -> [Int64] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // delete existing authors
        try deleteAuthors(mangaId: mangaId, in: db)
        
        var authorIds: [Int64] = []
        for name in names {
            if let author = try save(authorName: name, in: db) as? AuthorRecord,
               let authorId = author.id {
                authorIds.append(authorId.rawValue)
                try save(mangaId: mangaId, authorId: authorId.rawValue, in: db)
            }
        }
        return authorIds
    }
    
    // MARK: - Tag Operations (Similar pattern, abbreviated for brevity)
    
    public func fetch(tagId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try TagRecord.fetchOne(db, key: TagRecord.ID(rawValue: tagId))
    }
    
    public func fetch(tagName: String, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let normalizedName = tagName.lowercased().replacingOccurrences(of: " ", with: "")
        return try TagRecord
            .filter(TagRecord.Columns.normalizedName == normalizedName)
            .fetchOne(db)
    }
    
    public func fetchTags(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard let manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            return []
        }
        
        return try manga.tags.fetchAll(db)
    }
    
    @discardableResult
    public func save(tagName: String, displayName: String, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let normalizedName = tagName.lowercased().replacingOccurrences(of: " ", with: "")
        
        if let existing = try TagRecord
            .filter(TagRecord.Columns.normalizedName == normalizedName)
            .fetchOne(db) {
            return existing
        }
        
        var tag = TagRecord(
            normalizedName: normalizedName,
            displayName: displayName,
            canonicalId: nil
        )
        try tag.insert(db)
        return tag
    }
    
    public func save(mangaId: Int64, tagId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var junction = MangaTagRecord(
            mangaId: MangaRecord.ID(rawValue: mangaId),
            tagId: TagRecord.ID(rawValue: tagId)
        )
        try junction.insert(db, onConflict: .ignore)
    }
    
    public func deleteTags(mangaId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try MangaTagRecord
            .filter(MangaTagRecord.Columns.mangaId == mangaId)
            .deleteAll(db)
    }
    
    @discardableResult
    public func saveTags(_ tags: [(name: String, displayName: String)], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var savedTags: [TagRecord] = []
        for (name, displayName) in tags {
            if let tag = try save(tagName: name, displayName: displayName, in: db) as? TagRecord {
                savedTags.append(tag)
            }
        }
        return savedTags
    }
    
    public func saveTags(mangaId: Int64, tagIds: [Int64], in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        for tagId in tagIds {
            try save(mangaId: mangaId, tagId: tagId, in: db)
        }
    }
    
    public func saveTags(mangaId: Int64, names: [String], in db: Any) throws -> [Int64] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // delete existing tags
        try deleteTags(mangaId: mangaId, in: db)
        
        var tagIds: [Int64] = []
        for name in names {
            if let tag = try save(tagName: name, displayName: name, in: db) as? TagRecord,
               let tagId = tag.id {
                tagIds.append(tagId.rawValue)
                try save(mangaId: mangaId, tagId: tagId.rawValue, in: db)
            }
        }
        return tagIds
    }
    
    // MARK: - Cover Operations
    
    public func fetchCovers(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try CoverRecord
            .filter(CoverRecord.Columns.mangaId == mangaId)
            .order(CoverRecord.Columns.isPrimary.desc, CoverRecord.Columns.id)
            .fetchAll(db)
    }
    
    public func fetchPrimaryCover(mangaId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try CoverRecord
            .filter(CoverRecord.Columns.mangaId == mangaId)
            .filter(CoverRecord.Columns.isPrimary == true)
            .fetchOne(db)
    }
    
    public func deleteCovers(mangaId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try CoverRecord
            .filter(CoverRecord.Columns.mangaId == mangaId)
            .deleteAll(db)
    }
    
    @discardableResult
    public func save(cover: CoverData, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var coverRecord = CoverRecord(
            mangaId: MangaRecord.ID(rawValue: cover.mangaId),
            isPrimary: cover.isPrimary,
            localPath: cover.localPath,
            remotePath: cover.remotePath
        )
        try coverRecord.insert(db)
        return coverRecord
    }
    
    public func update(coverId: Int64, isPrimary: Bool, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var cover = try CoverRecord.fetchOne(db, key: CoverRecord.ID(rawValue: coverId)) else {
            throw StorageError.recordNotFound(table: "cover", id: String(coverId))
        }
        
        cover.isPrimary = isPrimary
        try cover.update(db)
    }
    
    @discardableResult
    public func saveCovers(_ covers: [CoverData], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var savedCovers: [CoverRecord] = []
        for cover in covers {
            if let saved = try save(cover: cover, in: db) as? CoverRecord {
                savedCovers.append(saved)
            }
        }
        return savedCovers
    }
    
    public func replaceCovers(mangaId: Int64, covers: [CoverData], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try deleteCovers(mangaId: mangaId, in: db)
        return try saveCovers(covers, in: db)
    }
    
    // MARK: - Alternative Title Operations
    
    public func fetchAlternativeTitles(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try AlternativeTitleRecord
            .filter(AlternativeTitleRecord.Columns.mangaId == mangaId)
            .fetchAll(db)
    }
    
    @discardableResult
    public func save(alternativeTitle: String, mangaId: Int64, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var altTitle = AlternativeTitleRecord(
            mangaId: MangaRecord.ID(rawValue: mangaId),
            title: alternativeTitle
        )
        try altTitle.insert(db, onConflict: .ignore)
        return altTitle
    }
    
    public func deleteAlternativeTitles(mangaId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try AlternativeTitleRecord
            .filter(AlternativeTitleRecord.Columns.mangaId == mangaId)
            .deleteAll(db)
    }
    
    @discardableResult
    public func saveAlternativeTitles(_ titles: [String], mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var savedTitles: [AlternativeTitleRecord] = []
        for title in titles {
            if let saved = try save(alternativeTitle: title, mangaId: mangaId, in: db) as? AlternativeTitleRecord {
                savedTitles.append(saved)
            }
        }
        return savedTitles
    }
    
    public func replaceAlternativeTitles(mangaId: Int64, titles: [String], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try deleteAlternativeTitles(mangaId: mangaId, in: db)
        return try saveAlternativeTitles(titles, mangaId: mangaId, in: db)
    }
    
    // MARK: - Origin Operations
    
    public func fetch(originId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try OriginRecord.fetchOne(db, key: OriginRecord.ID(rawValue: originId))
    }
    
    public func fetch(mangaId: Int64, sourceId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginRecord
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .filter(OriginRecord.Columns.sourceId == sourceId)
            .fetchOne(db)
    }
    
    public func fetchOrigins(mangaId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginRecord
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .order(OriginRecord.Columns.priority)
            .fetchAll(db)
    }
    
    public func fetchMaxPriority(mangaId: Int64, in db: Any) throws -> Int? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginRecord
            .select(max(OriginRecord.Columns.priority))
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .asRequest(of: Int.self)
            .fetchOne(db)
    }
    
    @discardableResult
    public func save(origin: OriginData, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // check if already exists
        if let existing = try fetch(mangaId: origin.mangaId, sourceId: origin.sourceId, in: db) {
            return existing
        }
        
        // get max priority for this manga
        let maxPriority = try fetchMaxPriority(mangaId: origin.mangaId, in: db) ?? -1
        
        var originRecord = OriginRecord(
            mangaId: MangaRecord.ID(rawValue: origin.mangaId),
            sourceId: SourceRecord.ID(rawValue: origin.sourceId),
            slug: origin.slug,
            url: origin.url.absoluteString,
            priority: maxPriority + 1,
            classification: origin.classification,
            status: origin.status
        )
        try originRecord.insert(db)
        return originRecord
    }
    
    public func update(originId: Int64, priority: Int, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var origin = try OriginRecord.fetchOne(db, key: OriginRecord.ID(rawValue: originId)) else {
            throw StorageError.recordNotFound(table: "origin", id: String(originId))
        }
        
        origin.priority = priority
        try origin.update(db)
    }
    
    public func update(originId: Int64, classification: Classification, status: Status, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var origin = try OriginRecord.fetchOne(db, key: OriginRecord.ID(rawValue: originId)) else {
            throw StorageError.recordNotFound(table: "origin", id: String(originId))
        }
        
        origin.classification = classification
        origin.status = status
        try origin.update(db)
    }
    
    public func delete(originId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try OriginRecord
            .filter(OriginRecord.Columns.id == originId)
            .deleteAll(db)
    }
    
    public func originExists(mangaId: Int64, sourceId: Int64, in db: Any) throws -> Bool {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try fetch(mangaId: mangaId, sourceId: sourceId, in: db) != nil
    }
    
    // MARK: - Scanlator Operations
    
    public func fetch(scanlatorId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try ScanlatorRecord.fetchOne(db, key: ScanlatorRecord.ID(rawValue: scanlatorId))
    }
    
    public func fetch(scanlatorName: String, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try ScanlatorRecord
            .filter(ScanlatorRecord.Columns.name == scanlatorName)
            .fetchOne(db)
    }
    
    @discardableResult
    public func save(scanlatorName: String, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        if let existing = try fetch(scanlatorName: scanlatorName, in: db) {
            return existing
        }
        
        var scanlator = ScanlatorRecord(name: scanlatorName)
        try scanlator.insert(db)
        return scanlator
    }
    
    @discardableResult
    public func saveScanlators(_ names: [String], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var scanlators: [ScanlatorRecord] = []
        for name in names {
            if let scanlator = try save(scanlatorName: name, in: db) as? ScanlatorRecord {
                scanlators.append(scanlator)
            }
        }
        return scanlators
    }
    
    public func fetchScanlators(names: [String], in db: Any) throws -> [String: Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var result: [String: Any] = [:]
        for name in names {
            if let scanlator = try fetch(scanlatorName: name, in: db) {
                result[name] = scanlator
            }
        }
        return result
    }
    
    // MARK: - Scanlator Priority Operations
    
    public func fetchPriorities(originId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .order(OriginScanlatorPriorityRecord.Columns.priority)
            .fetchAll(db)
    }
    
    public func fetchMaxPriority(originId: Int64, in db: Any) throws -> Int? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginScanlatorPriorityRecord
            .select(max(OriginScanlatorPriorityRecord.Columns.priority))
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .asRequest(of: Int.self)
            .fetchOne(db)
    }
    
    @discardableResult
    public func save(priority: ScanlatorPriorityData, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // check if already exists
        if try priorityExists(originId: priority.originId, scanlatorId: priority.scanlatorId, in: db) {
            try update(originId: priority.originId, scanlatorId: priority.scanlatorId, priority: priority.priority, in: db)
            return try OriginScanlatorPriorityRecord
                .filter(OriginScanlatorPriorityRecord.Columns.originId == priority.originId)
                .filter(OriginScanlatorPriorityRecord.Columns.scanlatorId == priority.scanlatorId)
                .fetchOne(db)!
        }
        
        var priorityRecord = OriginScanlatorPriorityRecord(
            originId: OriginRecord.ID(rawValue: priority.originId),
            scanlatorId: ScanlatorRecord.ID(rawValue: priority.scanlatorId),
            priority: priority.priority
        )
        try priorityRecord.insert(db)
        return priorityRecord
    }
    
    public func update(originId: Int64, scanlatorId: Int64, priority: Int, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var priorityRecord = try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .filter(OriginScanlatorPriorityRecord.Columns.scanlatorId == scanlatorId)
            .fetchOne(db) else {
            throw StorageError.recordNotFound(table: "origin_scanlator_priority", id: "\(originId)-\(scanlatorId)")
        }
        
        priorityRecord.priority = priority
        try priorityRecord.update(db)
    }
    
    public func deletePriorities(originId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .deleteAll(db)
    }
    
    public func priorityExists(originId: Int64, scanlatorId: Int64, in db: Any) throws -> Bool {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .filter(OriginScanlatorPriorityRecord.Columns.scanlatorId == scanlatorId)
            .fetchOne(db) != nil
    }
    
    @discardableResult
    public func savePriorities(_ priorities: [ScanlatorPriorityData], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var saved: [Any] = []
        for priority in priorities {
            saved.append(try save(priority: priority, in: db))
        }
        return saved
    }
    
    // MARK: - Chapter Operations
    
    public func fetch(chapterId: Int64, in db: Any) throws -> Any? {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        return try ChapterRecord.fetchOne(db, key: ChapterRecord.ID(rawValue: chapterId))
    }
    
    public func fetchChapters(originId: Int64, in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try ChapterRecord
            .filter(ChapterRecord.Columns.originId == originId)
            .order(ChapterRecord.Columns.number)
            .fetchAll(db)
    }
    
    public func fetchChaptersWithMetadata(mangaId: Int64, in db: Any) throws -> [ChapterWithMetadata] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // fetch manga to get showAllChapters preference
        guard let manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            return []
        }
        
        // simplified query that fetches best chapters directly
        let sql = """
            SELECT 
                c.id,
                c.originId,
                c.scanlatorId,
                c.slug,
                c.title,
                c.number,
                c.date,
                c.url,
                c.language,
                c.progress,
                c.lastReadAt,
                s.name as scanlatorName,
                src.icon as sourceIcon
            FROM \(BestChapterView.databaseTableName) bc
            JOIN \(ChapterRecord.databaseTableName) c ON c.id = bc.chapterId
            JOIN \(ScanlatorRecord.databaseTableName) s ON s.id = c.scanlatorId
            JOIN \(OriginRecord.databaseTableName) o ON o.id = c.originId
            LEFT JOIN \(SourceRecord.databaseTableName) src ON src.id = o.sourceId
            WHERE bc.mangaId = ?
              AND bc.rank = 1
            ORDER BY c.number ASC
            """
        
        let rows = try Row.fetchAll(db, sql: sql, arguments: [mangaId])
        
        return rows.compactMap { row in
            // safely extract values with proper types
            guard let chapterId = row["id"] as? Int64,
                  let originId = row["originId"] as? Int64,
                  let scanlatorId = row["scanlatorId"] as? Int64,
                  let slug = row["slug"] as? String,
                  let title = row["title"] as? String,
                  let number = row["number"] as? Double,
                  let date = row["date"] as? Date,
                  let urlString = row["url"] as? String,
                  let url = URL(string: urlString),
                  let language = row["language"] as? String,
                  let progress = row["progress"] as? Double,
                  let scanlatorName = row["scanlatorName"] as? String else {
                return nil
            }
            
            let lastReadAt = row["lastReadAt"] as? Date
            let sourceIconString = row["sourceIcon"] as? String
            let sourceIcon = sourceIconString.flatMap { URL(string: $0) }
            
            let chapter = ChapterRecord(
                id: ChapterRecord.ID(rawValue: chapterId),
                originId: OriginRecord.ID(rawValue: originId),
                scanlatorId: ScanlatorRecord.ID(rawValue: scanlatorId),
                slug: slug,
                title: title,
                number: number,
                date: date,
                url: url,
                language: LanguageCode(language),
                progress: progress,
                lastReadAt: lastReadAt
            )
            
            return ChapterWithMetadata(
                chapter: chapter,
                scanlatorName: scanlatorName,
                sourceIcon: sourceIcon
            )
        }
    }
    
    @discardableResult
    public func save(chapter: ChapterData, in db: Any) throws -> Any {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // check if already exists
        if try chapterExists(
            originId: chapter.originId,
            number: chapter.number,
            scanlatorId: chapter.scanlatorId,
            in: db
        ) {
            return try ChapterRecord
                .filter(ChapterRecord.Columns.originId == chapter.originId)
                .filter(ChapterRecord.Columns.number == chapter.number)
                .filter(ChapterRecord.Columns.scanlatorId == chapter.scanlatorId)
                .fetchOne(db)!
        }
        
        var chapterRecord = ChapterRecord(
            originId: OriginRecord.ID(rawValue: chapter.originId),
            scanlatorId: ScanlatorRecord.ID(rawValue: chapter.scanlatorId),
            slug: chapter.slug,
            title: chapter.title,
            number: chapter.number,
            date: chapter.date,
            url: chapter.url,
            language: chapter.language,
            progress: 0,
            lastReadAt: nil
        )
        try chapterRecord.insert(db)
        return chapterRecord
    }
    
    public func update(chapterId: Int64, progress: Double, lastReadAt: Date?, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard var chapter = try ChapterRecord.fetchOne(db, key: ChapterRecord.ID(rawValue: chapterId)) else {
            throw StorageError.recordNotFound(table: "chapter", id: String(chapterId))
        }
        
        chapter.progress = progress
        chapter.lastReadAt = lastReadAt
        try chapter.update(db)
    }
    
    public func deleteChapters(originId: Int64, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try ChapterRecord
            .filter(ChapterRecord.Columns.originId == originId)
            .deleteAll(db)
    }
    
    public func chapterExists(originId: Int64, number: Double, scanlatorId: Int64, in db: Any) throws -> Bool {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        return try ChapterRecord
            .filter(ChapterRecord.Columns.originId == originId)
            .filter(ChapterRecord.Columns.number == number)
            .filter(ChapterRecord.Columns.scanlatorId == scanlatorId)
            .fetchOne(db) != nil
    }
    
    @discardableResult
    public func saveChapters(_ chapters: [ChapterData], in db: Any) throws -> [Any] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var saved: [Any] = []
        for chapter in chapters {
            saved.append(try save(chapter: chapter, in: db))
        }
        return saved
    }
    
    public func updateChapters(_ chapterIds: [Int64], progress: Double, lastReadAt: Date?, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        for chapterId in chapterIds {
            try update(chapterId: chapterId, progress: progress, lastReadAt: lastReadAt, in: db)
        }
    }
    
    public func deleteChapters(_ chapterIds: [Int64], in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        try ChapterRecord
            .filter(chapterIds.contains(ChapterRecord.Columns.id))
            .deleteAll(db)
    }
    
    public func markChaptersRead(mangaId: Int64, upToNumber: Double, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let sql = """
            UPDATE \(ChapterRecord.databaseTableName)
            SET progress = 1.0, lastReadAt = ?
            WHERE originId IN (
                SELECT id FROM \(OriginRecord.databaseTableName)
                WHERE mangaId = ?
            )
            AND number <= ?
            """
        
        try db.execute(sql: sql, arguments: [Date(), mangaId, upToNumber])
    }
    
    public func markChaptersUnread(mangaId: Int64, fromNumber: Double, in db: Any) throws {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        let sql = """
            UPDATE \(ChapterRecord.databaseTableName)
            SET progress = 0, lastReadAt = NULL
            WHERE originId IN (
                SELECT id FROM \(OriginRecord.databaseTableName)
                WHERE mangaId = ?
            )
            AND number >= ?
            """
        
        try db.execute(sql: sql, arguments: [mangaId, fromNumber])
    }
    
    // MARK: - Collection Operations
    
    public func fetchCollections(mangaId: Int64, in db: Any) throws -> [(collection: Any, count: Int)] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        guard let manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
            return []
        }
        
        let collections = try manga.collections.fetchAll(db)
        
        return try collections.map { collection in
            guard let collectionId = collection.id else {
                return (collection: collection as Any, count: 0)
            }
            
            let count = try MangaCollectionRecord
                .filter(MangaCollectionRecord.Columns.collectionId == collectionId)
                .fetchCount(db)
            
            return (collection: collection as Any, count: count)
        }
    }
    
    // MARK: - Observation
    
    public func observe(entry: Entry) -> AsyncStream<[MangaBundle]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> [MangaBundle] in
                guard let self else { return [] }
                
                do {
                    // find manga ids matching the entry
                    let mangaIds = try self.findMangaIds(for: entry, in: db)
                    guard !mangaIds.isEmpty else { return [] }
                    
                    // fetch complete bundles for each manga
                    return try mangaIds.compactMap { mangaId in
                        try self.fetchMangaBundle(mangaId: mangaId, in: db)
                    }
                } catch {
                    // log error but continue observation
                    #if DEBUG
                    print("Error observing manga: \(error)")
                    #endif
                    return []
                }
            }
            
            let task = Task {
                do {
                    for try await bundles in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(bundles)
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
    
    // MARK: - Search Operations
    
    public func search(bySlug slug: String, sourceId: Int64?, in db: Any) throws -> [Int64] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        var query = OriginRecord
            .select(OriginRecord.Columns.mangaId)
            .filter(OriginRecord.Columns.slug == slug)
        
        if let sourceId = sourceId {
            query = query.filter(OriginRecord.Columns.sourceId == sourceId)
        }
        
        return try query
            .asRequest(of: Int64.self)
            .fetchAll(db)
    }
    
    public func search(byTitle title: String, in db: Any) throws -> [Int64] {
        guard let db = db as? Database else {
            throw StorageError.invalidCast(expected: "Database", actual: String(describing: type(of: db)))
        }
        
        // search in manga titles
        let mangaIds = try MangaRecord
            .select(MangaRecord.Columns.id)
            .filter(sql: "LOWER(title) = LOWER(?)", arguments: [title])
            .asRequest(of: Int64.self)
            .fetchAll(db)
        
        if !mangaIds.isEmpty {
            return mangaIds
        }
        
        // search in alternative titles
        return try AlternativeTitleRecord
            .select(AlternativeTitleRecord.Columns.mangaId)
            .filter(sql: "LOWER(title) = LOWER(?)", arguments: [title])
            .asRequest(of: Int64.self)
            .fetchAll(db)
    }
    
    // MARK: - Private Helper Methods
    
    private func findMangaIds(for entry: Entry, in db: Database) throws -> [Int64] {
        // if entry has manga id, use it directly
        if let mangaId = entry.mangaId {
            return [mangaId]
        }
        
        // search by slug first
        var mangaIds = try search(bySlug: entry.slug, sourceId: entry.sourceId, in: db)
        
        // if no slug matches, search by title
        if mangaIds.isEmpty {
            mangaIds = try search(byTitle: entry.title, in: db)
        }
        
        return mangaIds
    }
    
    private func fetchMangaBundle(mangaId: Int64, in db: Database) throws -> MangaBundle? {
        guard let manga = try fetch(mangaId: mangaId, in: db) else {
            return nil
        }
        
        let authors = try fetchAuthors(mangaId: mangaId, in: db)
        let tags = try fetchTags(mangaId: mangaId, in: db)
        let covers = try fetchCovers(mangaId: mangaId, in: db)
        let alternativeTitles = try fetchAlternativeTitles(mangaId: mangaId, in: db)
        let origins = try fetchOrigins(mangaId: mangaId, in: db)
        let chapters = try fetchChaptersWithMetadata(mangaId: mangaId, in: db)
        let collections = try fetchCollections(mangaId: mangaId, in: db)
        
        // fetch sources for origins
        var sources: [Int64: (source: Any, host: Any)] = [:]
        for origin in origins {
            if let originRecord = origin as? OriginRecord,
               let originId = originRecord.id?.rawValue,
               let sourceId = originRecord.sourceId?.rawValue,
               let sourceData = try fetch(sourceId: sourceId, in: db) {
                sources[originId] = sourceData
            }
        }
        
        return MangaBundle(
            manga: manga,
            authors: authors,
            tags: tags,
            covers: covers,
            alternativeTitles: alternativeTitles,
            origins: origins,
            sources: sources,
            chapters: chapters,
            collections: collections
        )
    }
}

//
//  MangaRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation

// MARK: - MangaRepository

public protocol MangaRepository: Sendable {
    
    // MARK: Remote Operations
    
    func remoteFetchManga(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> MangaDTO
    func remoteFetchChapters(sourceSlug: String, entrySlug: String, hostURL: URL) async throws -> [ChapterDTO]
    
    // MARK: Source Operations
    
    func fetch(sourceId: Int64, in db: Any) throws -> (source: Any, host: Any)?
    
    // MARK: Manga Operations
    
    func fetch(mangaId: Int64, in db: Any) throws -> Any?
    func fetch(bySlug slug: String, in db: Any) throws -> [Any]
    func fetch(byTitle title: String, in db: Any) throws -> [Any]
    func findOrCreate(title: String, synopsis: String, in db: Any) throws -> Any
    func update(mangaId: Int64, updatedAt: Date, lastFetchedAt: Date, in db: Any) throws
    func update(mangaId: Int64, fields: MangaUpdateFields, in db: Any) throws
    
    // MARK: Author Operations
    
    func fetch(authorId: Int64, in db: Any) throws -> Any?
    func fetch(authorName: String, in db: Any) throws -> Any?
    func fetchAuthors(mangaId: Int64, in db: Any) throws -> [Any]
    @discardableResult
    func save(authorName: String, in db: Any) throws -> Any
    func save(mangaId: Int64, authorId: Int64, in db: Any) throws
    func deleteAuthors(mangaId: Int64, in db: Any) throws
    
    // MARK: Author Bulk Operations
    
    @discardableResult
    func saveAuthors(_ names: [String], in db: Any) throws -> [Any]
    func saveAuthors(mangaId: Int64, authorIds: [Int64], in db: Any) throws
    func saveAuthors(mangaId: Int64, names: [String], in db: Any) throws -> [Int64]
    
    // MARK: Tag Operations
    
    func fetch(tagId: Int64, in db: Any) throws -> Any?
    func fetch(tagName: String, in db: Any) throws -> Any?
    func fetchTags(mangaId: Int64, in db: Any) throws -> [Any]
    @discardableResult
    func save(tagName: String, displayName: String, in db: Any) throws -> Any
    func save(mangaId: Int64, tagId: Int64, in db: Any) throws
    func deleteTags(mangaId: Int64, in db: Any) throws
    
    // MARK: Tag Bulk Operations
    
    @discardableResult
    func saveTags(_ tags: [(name: String, displayName: String)], in db: Any) throws -> [Any]
    func saveTags(mangaId: Int64, tagIds: [Int64], in db: Any) throws
    func saveTags(mangaId: Int64, names: [String], in db: Any) throws -> [Int64]
    
    // MARK: Cover Operations
    
    func fetchCovers(mangaId: Int64, in db: Any) throws -> [Any]
    func fetchPrimaryCover(mangaId: Int64, in db: Any) throws -> Any?
    func deleteCovers(mangaId: Int64, in db: Any) throws
    @discardableResult
    func save(cover: CoverData, in db: Any) throws -> Any
    func update(coverId: Int64, isPrimary: Bool, in db: Any) throws
    
    // MARK: Cover Bulk Operations
    
    @discardableResult
    func saveCovers(_ covers: [CoverData], in db: Any) throws -> [Any]
    func replaceCovers(mangaId: Int64, covers: [CoverData], in db: Any) throws -> [Any]
    
    // MARK: Alternative Title Operations
    
    func fetchAlternativeTitles(mangaId: Int64, in db: Any) throws -> [Any]
    @discardableResult
    func save(alternativeTitle: String, mangaId: Int64, in db: Any) throws -> Any
    func deleteAlternativeTitles(mangaId: Int64, in db: Any) throws
    
    // MARK: Alternative Title Bulk Operations
    
    @discardableResult
    func saveAlternativeTitles(_ titles: [String], mangaId: Int64, in db: Any) throws -> [Any]
    @discardableResult
    func replaceAlternativeTitles(mangaId: Int64, titles: [String], in db: Any) throws -> [Any]
    
    // MARK: Origin Operations
    
    func fetch(originId: Int64, in db: Any) throws -> Any?
    func fetch(mangaId: Int64, sourceId: Int64, in db: Any) throws -> Any?
    func fetchOrigins(mangaId: Int64, in db: Any) throws -> [Any]
    func fetchMaxPriority(mangaId: Int64, in db: Any) throws -> Int?
    @discardableResult
    func save(origin: OriginData, in db: Any) throws -> Any
    func update(originId: Int64, priority: Int, in db: Any) throws
    func update(originId: Int64, classification: Classification, status: Status, in db: Any) throws
    func delete(originId: Int64, in db: Any) throws
    func originExists(mangaId: Int64, sourceId: Int64, in db: Any) throws -> Bool
    
    // MARK: Scanlator Operations
    
    func fetch(scanlatorId: Int64, in db: Any) throws -> Any?
    func fetch(scanlatorName: String, in db: Any) throws -> Any?
    @discardableResult
    func save(scanlatorName: String, in db: Any) throws -> Any
    
    // MARK: Scanlator Bulk Operations
    
    @discardableResult
    func saveScanlators(_ names: [String], in db: Any) throws -> [Any]
    func fetchScanlators(names: [String], in db: Any) throws -> [String: Any]
    
    // MARK: Scanlator Priority Operations
    
    func fetchPriorities(originId: Int64, in db: Any) throws -> [Any]
    func fetchMaxPriority(originId: Int64, in db: Any) throws -> Int?
    @discardableResult
    func save(priority: ScanlatorPriorityData, in db: Any) throws -> Any
    func update(originId: Int64, scanlatorId: Int64, priority: Int, in db: Any) throws
    func deletePriorities(originId: Int64, in db: Any) throws
    func priorityExists(originId: Int64, scanlatorId: Int64, in db: Any) throws -> Bool
    
    // MARK: Scanlator Priority Bulk Operations
    
    @discardableResult
    func savePriorities(_ priorities: [ScanlatorPriorityData], in db: Any) throws -> [Any]
    
    // MARK: Chapter Operations
    
    func fetch(chapterId: Int64, in db: Any) throws -> Any?
    func fetchChapters(originId: Int64, in db: Any) throws -> [Any]
    func fetchChaptersWithMetadata(mangaId: Int64, in db: Any) throws -> [ChapterWithMetadata]
    @discardableResult
    func save(chapter: ChapterData, in db: Any) throws -> Any
    func update(chapterId: Int64, progress: Double, lastReadAt: Date?, in db: Any) throws
    func deleteChapters(originId: Int64, in db: Any) throws
    func chapterExists(originId: Int64, number: Double, scanlatorId: Int64, in db: Any) throws -> Bool
    
    // MARK: Chapter Bulk Operations
    
    @discardableResult
    func saveChapters(_ chapters: [ChapterData], in db: Any) throws -> [Any]
    func updateChapters(_ chapterIds: [Int64], progress: Double, lastReadAt: Date?, in db: Any) throws
    func deleteChapters(_ chapterIds: [Int64], in db: Any) throws
    func markChaptersRead(mangaId: Int64, upToNumber: Double, in db: Any) throws
    func markChaptersUnread(mangaId: Int64, fromNumber: Double, in db: Any) throws
    
    // MARK: Collection Operations
    
    func fetchCollections(mangaId: Int64, in db: Any) throws -> [(collection: Any, count: Int)]
    
    // MARK: Observation
    
    func observe(entry: Entry) -> AsyncStream<[MangaBundle]>
    
    // MARK: Search Operations
    
    func search(bySlug slug: String, sourceId: Int64?, in db: Any) throws -> [Int64]
    func search(byTitle title: String, in db: Any) throws -> [Int64]
}

// MARK: - Data Transfer Objects

public struct MangaBundle: @unchecked Sendable {
    public let manga: Any
    public let authors: [Any]
    public let tags: [Any]
    public let covers: [Any]
    public let alternativeTitles: [Any]
    public let origins: [Any]
    public let sources: [Int64: (source: Any, host: Any)]
    public let chapters: [ChapterWithMetadata]
    public let collections: [(collection: Any, count: Int)]
    
    public init(
        manga: Any,
        authors: [Any],
        tags: [Any],
        covers: [Any],
        alternativeTitles: [Any],
        origins: [Any],
        sources: [Int64: (source: Any, host: Any)],
        chapters: [ChapterWithMetadata],
        collections: [(collection: Any, count: Int)]
    ) {
        self.manga = manga
        self.authors = authors
        self.tags = tags
        self.covers = covers
        self.alternativeTitles = alternativeTitles
        self.origins = origins
        self.sources = sources
        self.chapters = chapters
        self.collections = collections
    }
}

public struct ChapterWithMetadata: @unchecked Sendable {
    public let chapter: Any
    public let scanlatorName: String
    public let sourceIcon: URL?
    
    public init(chapter: Any, scanlatorName: String, sourceIcon: URL?) {
        self.chapter = chapter
        self.scanlatorName = scanlatorName
        self.sourceIcon = sourceIcon
    }
}

public struct CoverData {
    public let mangaId: Int64
    public let isPrimary: Bool
    public let localPath: URL
    public let remotePath: URL
    
    public init(mangaId: Int64, isPrimary: Bool, localPath: URL, remotePath: URL) {
        self.mangaId = mangaId
        self.isPrimary = isPrimary
        self.localPath = localPath
        self.remotePath = remotePath
    }
}

public struct OriginData {
    public let mangaId: Int64
    public let sourceId: Int64
    public let slug: String
    public let url: URL
    public let priority: Int
    public let classification: Classification
    public let status: Status
    
    public init(
        mangaId: Int64,
        sourceId: Int64,
        slug: String,
        url: URL,
        priority: Int,
        classification: Classification,
        status: Status
    ) {
        self.mangaId = mangaId
        self.sourceId = sourceId
        self.slug = slug
        self.url = url
        self.priority = priority
        self.classification = classification
        self.status = status
    }
}

public struct ScanlatorPriorityData {
    public let originId: Int64
    public let scanlatorId: Int64
    public let priority: Int
    
    public init(originId: Int64, scanlatorId: Int64, priority: Int) {
        self.originId = originId
        self.scanlatorId = scanlatorId
        self.priority = priority
    }
}

public struct ChapterData {
    public let originId: Int64
    public let scanlatorId: Int64
    public let slug: String
    public let title: String
    public let number: Double
    public let date: Date
    public let url: URL
    public let language: LanguageCode
    
    public init(
        originId: Int64,
        scanlatorId: Int64,
        slug: String,
        title: String,
        number: Double,
        date: Date,
        url: URL,
        language: LanguageCode
    ) {
        self.originId = originId
        self.scanlatorId = scanlatorId
        self.slug = slug
        self.title = title
        self.number = number
        self.date = date
        self.url = url
        self.language = language
    }
}

public struct MangaUpdateFields {
    public var inLibrary: Bool?
    public var orientation: Orientation?
    public var showAllChapters: Bool?
    public var showHalfChapters: Bool?
    public var lastReadAt: Date?
    
    public init(
        inLibrary: Bool? = nil,
        orientation: Orientation? = nil,
        showAllChapters: Bool? = nil,
        showHalfChapters: Bool? = nil,
        lastReadAt: Date? = nil
    ) {
        self.inLibrary = inLibrary
        self.orientation = orientation
        self.showAllChapters = showAllChapters
        self.showHalfChapters = showHalfChapters
        self.lastReadAt = lastReadAt
    }
}

//
//  LibraryRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

// MARK: - Data Transfer Objects

public struct LibraryEntryData: @unchecked Sendable {
    public let manga: Any
    public let cover: Any
    public let unreadCount: Int
    public let primaryOrigin: Any
    
    public init(
        manga: Any,
        cover: Any,
        unreadCount: Int,
        primaryOrigin: Any
    ) {
        self.manga = manga
        self.cover = cover
        self.unreadCount = unreadCount
        self.primaryOrigin = primaryOrigin
    }
}

// MARK: - LibraryRepository

public protocol LibraryRepository: Sendable {
    
    // MARK: Library Operations
    
    func update(mangaId: Int64, inLibrary: Bool, in db: Any) throws
    func update(mangaId: Int64, addedDate: Date, in db: Any) throws
    
    // MARK: Collection Operations
    
    func fetch(collectionId: Int64, in db: Any) throws -> Any?
    func fetchCollections(in db: Any) throws -> [(collection: Any, count: Int)]
    
    @discardableResult
    func save(collection name: String, description: String?, in db: Any) throws -> Any
    func update(collectionId: Int64, fields: CollectionUpdateFields, in db: Any) throws
    func delete(collectionId: Int64, in db: Any) throws
    
    func add(mangaId: Int64, toCollection collectionId: Int64, in db: Any) throws
    func remove(mangaId: Int64, fromCollection collectionId: Int64, in db: Any) throws
    
    // MARK: Query Construction
    
    func createQuery(in db: Any) throws -> Any
    
    // MARK: Query Filtering
    
    func apply(search: String, to query: Any, in db: Any) throws -> Any
    func apply(collectionId: Int64, to query: Any, in db: Any) throws -> Any
    func apply(sourceIds: Set<Int64>, to query: Any, in db: Any) throws -> Any
    func apply(statuses: Set<Status>, to query: Any, in db: Any) throws -> Any
    func apply(classifications: Set<Classification>, to query: Any, in db: Any) throws -> Any
    func apply(dateFilter: DateFilter, column: String, to query: Any, in db: Any) throws -> Any
    func applyUnreadOnly(to query: Any, in db: Any) throws -> Any
    func applyDownloadedOnly(to query: Any, in db: Any) throws -> Any
    
    // MARK: Query Sorting
    
    func sort(byTitle query: Any, direction: SortDirection) throws -> Any
    func sort(byLastRead query: Any, direction: SortDirection) throws -> Any
    func sort(byLastUpdated query: Any, direction: SortDirection) throws -> Any
    func sort(byDateAdded query: Any, direction: SortDirection) throws -> Any
    func sort(byUnreadCount query: Any, direction: SortDirection, in db: Any) throws -> Any
    func sort(byChapterCount query: Any, direction: SortDirection, in db: Any) throws -> Any
    
    // MARK: Query Pagination
    
    func apply(limit: Int, to query: Any) throws -> Any
    func apply(afterId: Int64, sort: LibrarySort, to query: Any, in db: Any) throws -> Any
    
    // MARK: Manga Search Operations
    
    func fetchManga(bySlug slug: String, in db: Any) throws -> [Any]
    func fetchManga(byTitle title: String, in db: Any) throws -> [Any]
    func fetchOrigins(mangaId: Int64, in db: Any) throws -> [Any]
    
    // MARK: Count Operations
    
    func countUnreadChapters(mangaId: Int64, in db: Any) throws -> Int
    func countTotalChapters(mangaId: Int64, in db: Any) throws -> Int
    func count(results query: Any, in db: Any) throws -> Int
    
    // MARK: Fetch Operations
    
    func createCursor(for query: Any, in db: Any) throws -> Any
    func fetchEntryData(manga: Any, in db: Any) throws -> LibraryEntryData?
}

// MARK: - Supporting Types

public struct CollectionUpdateFields {
    public var name: String?
    public var description: String?
    
    public init(
        name: String? = nil,
        description: String? = nil
    ) {
        self.name = name
        self.description = description
    }
}

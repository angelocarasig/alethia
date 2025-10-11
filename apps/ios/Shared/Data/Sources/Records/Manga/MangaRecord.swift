//
//  MangaRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct MangaRecord: Codable, Hashable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var title: String
    var synopsis: String
    
    // config
    var inLibrary: Bool = false
    var addedAt: Date = .distantPast
    var updatedAt: Date = .now
    var lastFetchedAt: Date = .now
    var lastReadAt: Date = .distantPast
    var orientation: Domain.Orientation = .unknown
    var showAllChapters: Bool = false
    var showHalfChapters: Bool = false
    
    init(title: String, synopsis: String) {
        self.title = title
        self.synopsis = synopsis
    }
}

// MARK: - DatabaseRecord

extension MangaRecord {
    static var databaseTableName: String {
        "manga"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let title = Column(CodingKeys.title)
        static let synopsis = Column(CodingKeys.synopsis)
        
        static let inLibrary = Column(CodingKeys.inLibrary)
        static let addedAt = Column(CodingKeys.addedAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let lastFetchedAt = Column(CodingKeys.lastFetchedAt)
        static let lastReadAt = Column(CodingKeys.lastReadAt)
        static let orientation = Column(CodingKeys.orientation)
        static let showAllChapters = Column(CodingKeys.showAllChapters)
        static let showHalfChapters = Column(CodingKeys.showHalfChapters)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.title.name, .text)
                .notNull()
                .collate(.localizedCaseInsensitiveCompare)
            
            t.column(Columns.synopsis.name, .text).notNull()
            
            t.column(Columns.inLibrary.name, .boolean).notNull().defaults(to: false)
            t.column(Columns.addedAt.name, .datetime).notNull()
            t.column(Columns.updatedAt.name, .datetime).notNull()
            t.column(Columns.lastFetchedAt.name, .datetime).notNull()
            t.column(Columns.lastReadAt.name, .datetime).notNull()
            
            t.column(Columns.orientation.name, .text).notNull()
            t.column(Columns.showAllChapters.name, .boolean).notNull().defaults(to: false)
            t.column(Columns.showHalfChapters.name, .boolean).notNull().defaults(to: false)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // no indexes needed for manga table in initial schema
            // title has collation which provides indexing
            break
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Manga Chapters Association using BestChapterView

extension MangaRecord {
    /// Returns deduplicated chapters based on manga preferences using BestChapterView
    var chapters: QueryInterfaceRequest<ChapterRecord> {
        guard let mangaId = self.id else {
            // return empty request if no id
            return ChapterRecord.none()
        }
        
        // build the SQL that joins with BestChapterView
        let sql = """
            SELECT c.* FROM \(ChapterRecord.databaseTableName) c
            JOIN \(BestChapterView.databaseTableName) bc ON c.id = bc.chapterId
            WHERE bc.mangaId = ?
              AND bc.rank = 1
              AND (? = 1 OR bc.showHalfChapters = 1 OR bc.number = CAST(bc.number AS INTEGER))
            ORDER BY bc.number ASC
            """
        
        return ChapterRecord.filter(sql: sql, arguments: [mangaId.rawValue, showAllChapters ? 1 : 0])
    }
    
    /// Returns all chapters without deduplication (for showAllChapters mode)
    var allChapters: QueryInterfaceRequest<ChapterRecord> {
        guard let mangaId = self.id else {
            return ChapterRecord.none()
        }
        
        return ChapterRecord
            .joining(required: ChapterRecord.origin)
            .filter(sql: "\(OriginRecord.databaseTableName).mangaId = ?", arguments: [mangaId.rawValue])
            .order(ChapterRecord.Columns.number.asc)
    }
}

// MARK: - Manga Authors Association M-M

extension MangaRecord {
    static let mangaAuthors = hasMany(MangaAuthorRecord.self)
    
    static let authors = hasMany(
        AuthorRecord.self,
        through: mangaAuthors,
        using: MangaAuthorRecord.author
    )
    
    var authors: QueryInterfaceRequest<AuthorRecord> {
        request(for: MangaRecord.authors)
            .order(AuthorRecord.Columns.name.ascNullsLast)
    }
}

// MARK: - Manga Tags Association M-M

extension MangaRecord {
    static let mangaTags = hasMany(MangaTagRecord.self)
    
    static let tags = hasMany(
        TagRecord.self,
        through: mangaTags,
        using: MangaTagRecord.tag
    ).filter(TagRecord.Columns.canonicalId == nil)
    
    var tags: QueryInterfaceRequest<TagRecord> {
        request(for: MangaRecord.tags)
            .order(TagRecord.Columns.displayName.ascNullsLast)
    }
}

// MARK: - Manga Collections Association M-M

extension MangaRecord {
    static let mangaCollections = hasMany(MangaCollectionRecord.self)
    
    static let collections = hasMany(
        CollectionRecord.self,
        through: mangaCollections,
        using: MangaCollectionRecord.collection
    )
    
    var collections: QueryInterfaceRequest<CollectionRecord> {
        request(for: MangaRecord.collections)
            .order(CollectionRecord.Columns.name)
    }
}

// MARK: - Manga Covers Association 1-M

extension MangaRecord {
    static let covers = hasMany(CoverRecord.self)
    
    var cover: QueryInterfaceRequest<CoverRecord> {
        request(for: MangaRecord.covers)
            .filter(CoverRecord.Columns.isPrimary == true)
            .limit(1)
    }
    
    var covers: QueryInterfaceRequest<CoverRecord> {
        request(for: MangaRecord.covers)
            .order(CoverRecord.Columns.id.ascNullsLast)
    }
}

// MARK: - Manga Alternative Titles Association 1-M

extension MangaRecord {
    static let alternativeTitles = hasMany(AlternativeTitleRecord.self)
        .order(AlternativeTitleRecord.Columns.title)
    
    var alternativeTitles: QueryInterfaceRequest<AlternativeTitleRecord> {
        request(for: MangaRecord.alternativeTitles)
    }
}

// MARK: - Manga Origins Association 1-M

extension MangaRecord {
    static let origins = hasMany(OriginRecord.self)
        .order(OriginRecord.Columns.priority.ascNullsLast)
    
    var origin: QueryInterfaceRequest<OriginRecord> {
        request(for: MangaRecord.origins)
            .filter(OriginRecord.Columns.priority >= 0)
            .order(OriginRecord.Columns.priority.asc)
            .limit(1)
    }
    
    var origins: QueryInterfaceRequest<OriginRecord> {
        request(for: MangaRecord.origins)
    }
}

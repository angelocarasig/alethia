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

internal struct MangaRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var title: String
    var synopsis: AttributedString
    
    // config
    var inLibrary: Bool = false
    var addedAt: Date = .distantPast
    var updatedAt: Date = .now
    var lastFetchedAt: Date = .now
    var lastReadAt: Date = .distantPast
    var orientation: Domain.Orientation = .unknown
    var showAllChapters: Bool = false
    var showHalfChapters: Bool = false
    
    init(title: String, synopsis: AttributedString) {
        self.title = title
        self.synopsis = synopsis
    }
}

extension MangaRecord: FetchableRecord, MutablePersistableRecord {
    public static var databaseTableName: String {
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
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: Manga Authors Association M-M
extension MangaRecord {
    static let mangaAuthors = hasMany(MangaAuthorRecord.self)
    
    static let authors = hasMany(
        AuthorRecord.self,
        through: mangaAuthors,
        using: MangaAuthorRecord.author
    )
    
    // convenience request for fetching authors
    var authors: QueryInterfaceRequest<AuthorRecord> {
        request(for: MangaRecord.authors)
            .order(AuthorRecord.Columns.name.ascNullsLast)
    }
}

// MARK: Manga Tags Association M-M
extension MangaRecord {
    static let mangaTags = hasMany(MangaTagRecord.self)
    
    static let tags = hasMany(
        TagRecord.self,
        through: mangaTags,
        using: MangaTagRecord.tag
    ).filter(TagRecord.Columns.canonicalId == nil) // we should get only the main canonical tags
    
    // convenience request for fetching tags
    var tags: QueryInterfaceRequest<TagRecord> {
        request(for: MangaRecord.tags)
            .order(TagRecord.Columns.displayName.ascNullsLast)
    }
}

// MARK: Manga Collections Association M-M
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


// MARK: Manga Covers Association 1-M
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

// MARK: Manga Alternative Titles Association 1-M
extension MangaRecord {
    static let alternativeTitles = hasMany(AlternativeTitleRecord.self)
        .order(AlternativeTitleRecord.Columns.title)
    
    var alternativeTitles: QueryInterfaceRequest<AlternativeTitleRecord> {
        request(for: MangaRecord.alternativeTitles)
    }
}

// MARK: Manga Origins Association 1-M
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

// MARK: Manga Chapter Association with Origin + Scanlator Priority
/// Fetches chapters based on manga display preferences and priority rules.
///
/// Display modes:
/// - showAllChapters = true: Returns ALL chapters from ALL origins (no deduplication)
/// - showAllChapters = false: Returns deduplicated chapters based on priority
///   - showHalfChapters = true: Includes decimal chapters (1, 1.1, 1.2, 2)
///   - showHalfChapters = false: Whole chapters only (1, 2, 3)
///
/// CASE 1: showAllChapters = true (returns everything)
/// ═══════════════════════════════════════════════════
/// Raw data from all origins:
/// +--------+--------+----------+
/// | number | origin | scanlator|
/// +--------+--------+----------+
/// | 1      | E      | X        |
/// | 1      | E      | Y        |
/// | 1      | F      | X        |
/// | 1.5    | E      | X        |
/// | 2      | F      | X        |
/// +--------+--------+----------+
/// ↓ NO TRANSFORMATION - ALL RETURNED
///
/// CASE 2: showAllChapters = false, showHalfChapters = false
/// ═══════════════════════════════════════════════════════════
/// Step 1: Filter out decimal chapters (WHERE number = CAST(number AS INTEGER))
/// +--------+--------+----------+------+------+
/// | number | origin | o_prior  | scan | s_pr |
/// +--------+--------+----------+------+------+
/// | 1      | E      | 0        | X    | 0    | ✓
/// | 1      | E      | 0        | Y    | 1    | ✓
/// | 1      | F      | 1        | X    | 0    | ✓
/// | 1.5    | E      | 0        | X    | 0    | ✗ filtered
/// | 2      | F      | 1        | X    | 0    | ✓
/// +--------+--------+----------+------+------+
///
/// Step 2: Apply ROW_NUMBER() OVER (PARTITION BY number ORDER BY priorities)
/// +--------+--------+------+------+----+
/// | number | origin | scan | s_pr | rn |
/// +--------+--------+------+------+----+
/// | 1      | E      | X    | 0    | 1  |
/// | 1      | E      | Y    | 1    | 2  |
/// | 1      | F      | X    | 0    | 3  |
/// | 2      | F      | X    | 0    | 1  |
/// +--------+--------+------+------+----+
///
/// Step 3: Filter WHERE rn = 1 (keep best priority per chapter)
/// +--------+--------+----------+
/// | number | origin | scanlator|
/// +--------+--------+----------+
/// | 1      | E      | X        |
/// | 2      | F      | X        |
/// +--------+--------+----------+
///
/// CASE 3: showAllChapters = false, showHalfChapters = true
/// ══════════════════════════════════════════════════════════
/// Step 1: Keep all chapters (no decimal filtering)
/// +--------+--------+----------+------+------+
/// | number | origin | o_prior  | scan | s_pr |
/// +--------+--------+----------+------+------+
/// | 1      | E      | 0        | X    | 0    |
/// | 1      | E      | 0        | Y    | 1    |
/// | 1      | F      | 1        | X    | 0    |
/// | 1.5    | E      | 0        | X    | 0    | ← kept
/// | 1.5    | F      | 1        | Y    | 1    | ← kept
/// | 2      | F      | 1        | X    | 0    |
/// +--------+--------+----------+------+------+
///
/// Step 2: Apply ROW_NUMBER() OVER (PARTITION BY number ORDER BY priorities)
/// +--------+--------+------+------+----+
/// | number | origin | scan | s_pr | rn |
/// +--------+--------+------+------+----+
/// | 1      | E      | X    | 0    | 1  |
/// | 1      | E      | Y    | 1    | 2  |
/// | 1      | F      | X    | 0    | 3  |
/// | 1.5    | E      | X    | 0    | 1  |
/// | 1.5    | F      | Y    | 1    | 2  |
/// | 2      | F      | X    | 0    | 1  |
/// +--------+--------+------+------+----+
///
/// Step 3: Filter WHERE rn = 1 (keep best priority per chapter)
/// +--------+--------+----------+
/// | number | origin | scanlator|
/// +--------+--------+----------+
/// | 1      | E      | X        |
/// | 1.5    | E      | X        |
/// | 2      | F      | X        |
/// +--------+--------+----------+
extension MangaRecord {
    var chapters: QueryInterfaceRequest<ChapterRecord> {
        guard let mangaId = self.id?.rawValue else {
            return ChapterRecord.none()
        }
        
        // show all chapters - no deduplication, just filter by manga
        if showAllChapters {
            return ChapterRecord
                .joining(required: ChapterRecord.origin)
                .filter(sql: "origin.mangaId = ?", arguments: [mangaId])
                .order(ChapterRecord.Columns.number.asc)
        }
        
        // deduplicated chapters with priority rules
        let numberFilter = showHalfChapters
        ? ""
        : "AND chapter.number = CAST(chapter.number AS INTEGER)"
        
        return ChapterRecord
            .select(sql: """
                SELECT c.* FROM (
                    SELECT chapter.*,
                           ROW_NUMBER() OVER (
                               PARTITION BY chapter.number 
                               ORDER BY origin.priority ASC,
                                        COALESCE(osp.priority, 999) ASC
                           ) as rn
                    FROM chapter
                    JOIN origin ON origin.id = chapter.originId
                    LEFT JOIN origin_scanlator_priority osp 
                        ON osp.originId = origin.id 
                        AND osp.scanlatorId = chapter.scanlatorId
                    WHERE origin.mangaId = ?
                    \(numberFilter)
                ) c
                WHERE c.rn = 1
                ORDER BY c.number ASC
                """, arguments: [mangaId])
            .asRequest(of: ChapterRecord.self)
    }
}

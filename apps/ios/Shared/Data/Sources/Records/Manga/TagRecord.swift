//
//  TagRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged

internal struct TagRecord: Codable, DatabaseRecord {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var normalizedName: String
    var displayName: String
    
    /// References the ID of another TagRecord where:
    ///   nil = canonical tag
    ///   non-nil = alias pointing to canonical
    var canonicalId: TagRecord.ID?
    
    var isCanonical: Bool {
        canonicalId == nil
    }
}

// MARK: - DatabaseRecord

extension TagRecord {
    static var databaseTableName: String {
        "tag"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let normalizedName = Column(CodingKeys.normalizedName)
        static let displayName = Column(CodingKeys.displayName)
        static let canonicalId = Column(CodingKeys.canonicalId)
    }
    
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, options: [.ifNotExists]) { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.normalizedName.name, .text)
                .notNull()
                .collate(.localizedCaseInsensitiveCompare)
            
            t.column(Columns.displayName.name, .text)
                .notNull()
                .collate(.caseInsensitiveCompare)
            
            t.column(Columns.canonicalId.name, .integer)
                .references(databaseTableName, onDelete: .setNull)
        }
    }
    
    static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: DatabaseVersion) throws {
        switch version {
        case ..<DatabaseVersion(1, 0, 0):
            // no additional indexes needed in initial schema
            break
        default:
            break
        }
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

// MARK: - Associations

extension TagRecord {
    // alias -> canonical tag (many-to-one)
    static let canonical = belongsTo(TagRecord.self, key: "canonical")
    
    // canonical -> all its aliases (one-to-many)
    static let aliases = hasMany(TagRecord.self, key: "aliases")
        .order(Columns.displayName)
    
    var canonical: QueryInterfaceRequest<TagRecord> {
        request(for: TagRecord.canonical)
    }
    
    var aliases: QueryInterfaceRequest<TagRecord> {
        request(for: TagRecord.aliases)
    }
}

extension TagRecord {
    static let mangaTags = hasMany(MangaTagRecord.self)
    static let directManga = hasMany(
        MangaRecord.self,
        through: mangaTags,
        using: MangaTagRecord.manga
    )
    
    /// When you call tag.manga on ANY of these:
    /// 1. Resolves to canonical ID (1)
    /// 2. Finds all tags where id=1 OR canonicalId=1 → [1,2,3]
    /// 3. Returns manga tagged with any of those IDs
    var manga: QueryInterfaceRequest<MangaRecord> {
        let resolvedId = canonicalId ?? id!
        
        let tagIds = TagRecord
            .filter(TagRecord.Columns.id == resolvedId ||
                    TagRecord.Columns.canonicalId == resolvedId)
            .select(TagRecord.Columns.id)
        
        return MangaRecord
            .joining(required: MangaRecord.mangaTags
                .filter(tagIds.contains(MangaTagRecord.Columns.tagId)))
            .distinct()
    }
}

// MARK: - Query Extensions

extension DerivableRequest<TagRecord> {
    func canonical() -> Self {
        filter(TagRecord.Columns.canonicalId == nil)
    }
    
    func matching(_ searchTerm: String) -> Self {
        filter(TagRecord.Columns.normalizedName == searchTerm)
    }
}

//
//  Entry.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import GRDB

internal typealias Entry = Domain.Models.Virtual.Entry

public extension Domain.Models.Virtual {
    struct Entry: Identifiable, Hashable, Decodable {
        // MARK: - Properties
        
        /// underlying manga id if it exists
        ///
        /// optional as it can be initialized via
        /// - local library/db, where it does exist for sure
        /// - source route content, where it comes from a remote server
        public var mangaId: Int64?
        
        /// underlying source id if it exists
        ///
        /// optional as it can be initialized via
        /// - local library/db, which retrieves the highest priority origin's sourceId
        /// - remote server, either from a search/source route content to distinguish
        /// how each entry is unique in these views
        public var sourceId: Int64?
        
        /// title of entry
        public var title: String
        
        /// a unique identifier used for building fetch url
        ///
        /// maps from origin's slug, which is used in matching algorithms to determine
        /// whether in library/partial match etc.
        public var slug: String
        
        /// cover remote url
        public var cover: String
        
        /// fetch url to retrieve details content from the remote server, or nil if
        /// coming from a detached source
        public var fetchUrl: String?
        
        /// unread count for the entry's underlying manga chapter list count
        public var unread: Int = 0
        
        /// match type
        public var match: Domain.Models.Enums.EntryMatch = .none
        
        // MARK: - Internal
        /// these properties are required for in-library filtering and are mirrors of default
        /// manga internal properties
        
        public var inLibrary: Bool
        public var addedAt: Date
        public var updatedAt: Date
        public var lastReadAt: Date?
        
        init(
            mangaId: Int64? = nil,
            sourceId: Int64? = nil,
            title: String,
            slug: String,
            cover: String,
            fetchUrl: String? = nil,
            unread: Int = 0,
            match: Domain.Models.Enums.EntryMatch = .none,
            inLibrary: Bool,
            addedAt: Date = .distantPast,
            updatedAt: Date = .distantPast,
            lastReadAt: Date? = nil
        ) {
            self.mangaId = mangaId
            self.sourceId = sourceId
            self.title = title
            self.slug = slug
            self.cover = cover
            self.fetchUrl = fetchUrl
            self.unread = unread
            self.match = match
            self.inLibrary = inLibrary
            self.addedAt = addedAt
            self.updatedAt = updatedAt
            self.lastReadAt = lastReadAt
        }
    }
}

// MARK: - Computed
public extension Entry {
    var id: String {
        // coming from a source - use the fetch url
        if let fetchUrl = fetchUrl {
            return fetchUrl
        }
        
        // coming from library - use library related props
        else if let mangaId = mangaId {
            return "manga-\(mangaId)-\(match)"
        }
        
        // who knows when this would happen but as an extra measure
        else if let sourceId = sourceId {
            return "source-\(sourceId)-\(slug)"
        }
        
        // fallback which shouldn't generally happen
        else {
            return "unknown-\(title)-\(slug)"
        }
    }
}

// MARK: - Database Conformance
extension Entry: TableRecord {
    public enum Columns {
        // grouping by how they are selected
        
        // base - manga props
        public static let mangaId     = Column(CodingKeys.mangaId)
        public static let title       = Column(CodingKeys.title)
        public static let inLibrary   = Column(CodingKeys.inLibrary)
        public static let addedAt     = Column(CodingKeys.addedAt)
        public static let updatedAt   = Column(CodingKeys.updatedAt)
        public static let lastReadAt  = Column(CodingKeys.lastReadAt)
        
        // from manga 1-M relations
        // cover with property `active`
        public static let cover       = Column(CodingKeys.cover)
        
        // from best origin's source
        public static let sourceId    = Column(CodingKeys.sourceId)
        public static let slug        = Column(CodingKeys.slug)
        
        // from calculated
        // via joining host baseUrl + source.slug + "manga" + origin.slug
        public static let fetchUrl    = Column(CodingKeys.fetchUrl)
        
        // via best chapter fetchCount()
        public static let unread      = Column(CodingKeys.unread)
        
        // should default to .none as will be filled from different use-case or remain .none (in case of library screen)
        public static let match       = Column(CodingKeys.match)
    }
}

internal extension Entry {
    static var asRequest: SQLRequest<Entry> {
        // all query props in base
        let base = """
            SELECT
                m.id AS mangaId,
                m.title AS title,
                m.inLibrary AS inLibrary,
                m.addedAt AS addedAt,
                m.updatedAt AS updatedAt,
                m.lastReadAt AS lastReadAt,
                
                best_origin.sourceId AS sourceId,
                best_origin.slug AS slug,
        
                (RTRIM(h.baseUrl, '/') || '/' || 
                 LTRIM(s.path, '/') || '/manga/' || 
                 best_origin.slug) AS fetchUrl,
                
                active_cover.url AS cover,
                
                CAST(IFNULL(unread_stats.unread_count, 0) AS INTEGER) AS unread
        """
        
        // start from manga m
        let from = """
            FROM manga m
        """
        
        // aliased subquery as best origin
        let origin = """
            LEFT JOIN (
                SELECT o.mangaId, o.sourceId, o.slug
                FROM origin o
                WHERE o.priority = (
                    SELECT MIN(priority) 
                    FROM origin o2 
                    WHERE o2.mangaId = o.mangaId
                )
            ) best_origin ON best_origin.mangaId = m.id
        """
        
        // relevant best origin's source and host
        let sourcehost = """
            LEFT JOIN source s ON s.id = best_origin.sourceId
            LEFT JOIN host h ON h.id = s.hostId
        """
        
        // active cover
        let cover = """
            LEFT JOIN (
                SELECT c.mangaId, c.url
                FROM cover c
                WHERE c.active = 1
            ) active_cover ON active_cover.mangaId = m.id
        """
        
        // unread
        let unread = """
            LEFT JOIN (
                SELECT 
                    bc.mangaId,
                    COUNT(*) as unread_count
                FROM best_chapter bc
                WHERE bc.rank = 1
                AND (bc.showHalfChapters = 1 OR CAST(bc.number AS INTEGER) = bc.number)
                AND (bc.progress IS NULL OR bc.progress < 1.0)
                GROUP BY bc.mangaId
            ) unread_stats ON unread_stats.mangaId = m.id
        """
        
        let sql = [
            base,
            from,
            origin,
            sourcehost,
            cover,
            unread
        ].joined(separator: "\n\n")
        
        return SQLRequest<Entry>(sql: sql)
    }
}

// MARK: - Database View Definition + Migrations
extension Entry: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(view: databaseTableName, options: [ViewOptions.ifNotExists], as: asRequest)
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

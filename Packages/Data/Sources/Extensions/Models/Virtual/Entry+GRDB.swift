//
//  Entry+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import GRDB
import Domain

private typealias Entry = Domain.Models.Virtual.Entry
private typealias Manga = Domain.Models.Persistence.Manga
private typealias Cover = Domain.Models.Persistence.Cover
private typealias Origin = Domain.Models.Persistence.Origin
private typealias Source = Domain.Models.Persistence.Source
private typealias Host = Domain.Models.Persistence.Host
private typealias Chapter = Domain.Models.Persistence.Chapter

// MARK: - Database Conformance
extension Entry: @retroactive FetchableRecord {}

extension Entry: @retroactive TableRecord {
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
    static var asRequest: SQLRequest<Domain.Models.Virtual.Entry> {
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
extension Entry: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(view: databaseTableName, options: [ViewOptions.ifNotExists], as: asRequest)
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

public extension Entry {
    static func fetchAll(in db: Database) throws -> [Domain.Models.Virtual.Entry] {
        return try asRequest.fetchAll(db)
    }
}

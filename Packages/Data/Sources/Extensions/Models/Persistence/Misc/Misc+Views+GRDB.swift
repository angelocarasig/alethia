//
//  Misc+Views+GRDB.swift
//  Data
//
//  Created by Claude on 15/6/2025.
//

import Foundation
import GRDB
import Domain


private typealias Misc = Domain.Models.Persistence.Misc
private typealias Chapter = Domain.Models.Persistence.Chapter
private typealias Origin = Domain.Models.Persistence.Origin
private typealias Channel = Domain.Models.Persistence.Channel
private typealias Manga = Domain.Models.Persistence.Manga

// MARK: - Database Table Definition + Migrations
extension Misc.Views: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(view: BestChapter.databaseTableName, options: [ViewOptions.ifNotExists], as: BestChapter.asRequest)
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

private struct BestChapter {
    static let databaseTableName: String = "best_chapter"
    
    static var asRequest: SQLRequest<Chapter> {
        let base = """
            SELECT 
                c.id,
                c.originId,
                c.scanlatorId,
                c.title,
                c.slug,
                c.number,
                c.date,
                c.progress,
                c.localPath,
                
                o.mangaId,
                m.showHalfChapters,
                
                ROW_NUMBER() OVER (
                    PARTITION BY o.mangaId, c.number 
                    ORDER BY o.priority ASC, ch.priority ASC
                ) as rank
        """
        
        let from = """
            FROM chapter c
        """
        
        let joins = """
            JOIN origin o ON c.originId = o.id
            JOIN channel ch ON ch.originId = o.id AND ch.scanlatorId = c.scanlatorId
            JOIN manga m ON o.mangaId = m.id
        """
        
        let sql = [
            base,
            from,
            joins
        ].joined(separator: "\n\n")
        
        return SQLRequest<Chapter>(sql: sql)
    }
}

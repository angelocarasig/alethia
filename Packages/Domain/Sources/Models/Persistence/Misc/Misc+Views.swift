//
//  Misc+Views.swift
//  Domain
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB

internal typealias Views = Domain.Models.Persistence.Misc.Views

public extension Domain.Models.Persistence.Misc {
    struct Views {}
}

extension Views: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(view: BestChapter.databaseTableName, options: [ViewOptions.ifNotExists], as: BestChapter.asRequest)
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

private struct BestChapter {
    static let databaseTableName: String = "best_chapter"
    
    static var asRequest: SQLRequest<Domain.Models.Persistence.Chapter> {
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
        
        return SQLRequest<Domain.Models.Persistence.Chapter>(sql: sql)
    }
}

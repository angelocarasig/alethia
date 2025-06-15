//
//  Misc+VirtualTables.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import GRDB

private typealias Misc = Domain.Models.Persistence.Misc

extension Misc.VirtualTables: @retroactive Data.Infrastructure.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try MangaTitleFTS5.createTable(db: db)
        try MangaAltTitleFTS5.createTable(db: db)
    }
    
    public static func migrate(with migrator: inout GRDB.DatabaseMigrator, from version: Data.Infrastructure.Version) throws {
        // nothing for now
    }
}

internal struct MangaTitleFTS5 {
    static let databaseTableName: String = "manga_title_fts"
    static let syncTable: String = Domain.Models.Persistence.Manga.databaseTableName
    
    static func createTable(db: Database) throws {
        try db.create(virtualTable: databaseTableName, options: [.ifNotExists], using: FTS5()) { t in
            /// https://www.sqlite.org/fts5.html#tokenizers
            t.tokenizer = .unicode61(diacritics: .remove)
            
            // synchronize with manga table
            t.synchronize(withTable: syncTable)
            
            // only index the title column
            t.column(Domain.Models.Persistence.Manga.Columns.title.name)
        }
    }
}

internal struct MangaAltTitleFTS5 {
    static let databaseTableName: String = "manga_alttitle_fts"
    static let syncTable: String = Domain.Models.Persistence.Title.databaseTableName
    
    static func createTable(db: Database) throws {
        try db.create(virtualTable: databaseTableName, options: [.ifNotExists], using: FTS5()) { t in
            /// https://www.sqlite.org/fts5.html#tokenizers
            t.tokenizer = .unicode61(diacritics: .remove)
            
            // synchronize with title table
            t.synchronize(withTable: syncTable)
            
            // index title column
            t.column(Domain.Models.Persistence.Title.Columns.title.name)
            
            // store mangaId for filtering but don't index it
            t.column(Domain.Models.Persistence.Title.Columns.mangaId.name).notIndexed()
        }
    }
}

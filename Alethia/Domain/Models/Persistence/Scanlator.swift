//
//  Scanlator.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Scanlator: Codable, Identifiable {
    var id: Int64?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Scanlator {
    static let chapters = hasMany(Chapter.self)
    static let originScanlator = hasMany(OriginScanlator.self)
    static let origins = hasMany(Origin.self, through: originScanlator, using: OriginScanlator.origin)
}

extension Scanlator {
    var chapters: QueryInterfaceRequest<Chapter> {
        request(for: Scanlator.chapters)
    }
    
    var origins: QueryInterfaceRequest<Origin> {
        request(for: Scanlator.origins)
    }
}

extension Scanlator: TableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
    }
}

extension Scanlator: FetchableRecord {}
extension Scanlator: PersistableRecord {}

extension Scanlator: DatabaseUnique {
    static func uniqueFilter(for instance: Scanlator) -> QueryInterfaceRequest<Scanlator> {
        filter(Columns.name == instance.name)
    }
}

extension Scanlator: DatabaseModel {
    static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.name.name, .text)
                .notNull()
                .unique()
                .collate(.nocase)
                .indexed()
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        if version <= Version(1, 0, 4) {
            migrator.registerMigration("migrate to global scanlators") { db in
                // 1. Rename old table
                try db.rename(table: databaseTableName, to: "\(databaseTableName)_old")
                
                // 2. Create new scanlator table
                try createTable(db: db)
                
                // 3. Create OriginScanlator table
                try OriginScanlator.createTable(db: db)
                
                // 4. Insert unique scanlator names
                try db.execute(sql: """
                    INSERT INTO \(databaseTableName) (name)
                    SELECT DISTINCT name FROM \(databaseTableName)_old
                """)
                
                // 5. Create origin-scanlator relationships
                try db.execute(sql: """
                    INSERT INTO \(OriginScanlator.databaseTableName) (originId, scanlatorId, priority)
                    SELECT 
                        old.originId,
                        new.id,
                        old.priority
                    FROM \(databaseTableName)_old old
                    JOIN \(databaseTableName) new ON old.name = new.name COLLATE NOCASE
                """)
                
                // 6. Update chapters to reference new scanlator IDs
                try db.execute(sql: """
                    UPDATE \(Chapter.databaseTableName)
                    SET scanlatorId = (
                        SELECT new.id
                        FROM \(databaseTableName)_old old
                        JOIN \(databaseTableName) new ON old.name = new.name COLLATE NOCASE
                        WHERE old.id = \(Chapter.databaseTableName).scanlatorId
                    )
                """)
                
                // 7. Drop old table
                try db.drop(table: "\(databaseTableName)_old")
            }
        }
    }
}

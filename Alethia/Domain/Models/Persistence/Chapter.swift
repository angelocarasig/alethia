//
//  Chapter.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Chapter: Codable, Identifiable, QueueOperationIdentifiable {
    var id: Int64?
    var queueOperationId: QueueOperationId {
        "chapter-\(id ?? -1)"
    }
    
    var originId: Int64
    var scanlatorId: Int64
    
    var title: String
    var slug: String
    var number: Double
    var date: Date
    
    var progress: Double = 0.0
    var localPath: String? = nil
    
    var read: Bool {
        progress == 1.0
    }
    
    var downloaded: Bool {
        localPath != nil
    }
    
    func toString() -> String {
        return "Chapter \(self.number.toString()) \(title.isEmpty ? "" : " - \(title)")"
    }
}

extension Chapter {
    static let origin = belongsTo(Origin.self)
    static let scanlator = belongsTo(Scanlator.self)
}

extension Chapter {
    var origin: QueryInterfaceRequest<Origin> {
        request(for: Chapter.origin)
    }
    
    var scanlator: QueryInterfaceRequest<Scanlator> {
        request(for: Chapter.scanlator)
    }
}

extension Chapter: TableRecord {
    enum Columns {
        static let id = Column(Chapter.CodingKeys.id)
        static let originId = Column(Chapter.CodingKeys.originId)
        static let scanlatorId = Column(Chapter.CodingKeys.scanlatorId)
        
        static let title = Column(Chapter.CodingKeys.title)
        static let slug = Column(Chapter.CodingKeys.slug)
        static let number = Column(Chapter.CodingKeys.number)
        static let date = Column(Chapter.CodingKeys.date)
        
        static let progress = Column(Chapter.CodingKeys.progress)
        static let localPath = Column(Chapter.CodingKeys.localPath)
    }
}

extension Chapter: FetchableRecord {}
extension Chapter: PersistableRecord {}

extension Chapter: DatabaseModel {
    static var version: Version = Version(1, 0, 0)
    
    static func createTable(db: Database) throws {
        try db.create(table: self.databaseTableName, body: { t in
            t.autoIncrementedPrimaryKey(Columns.id.name)
            
            t.column(Columns.title.name, .text).notNull()
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.number.name, .double).notNull()
            t.column(Columns.date.name, .datetime).notNull()
            
            t.column(Columns.progress.name, .double).notNull()
            t.column(Columns.localPath.name, .text)
            
            t.column(Columns.originId.name, .integer)
                .notNull()
                .indexed()
                .references(Origin.databaseTableName, onDelete: .cascade)
            
            t.column(Columns.scanlatorId.name, .integer)
                .notNull()
                .indexed()
                .references(Scanlator.databaseTableName, onDelete: .restrict)
        })
    }
    
    static func migrate(with migrator: inout DatabaseMigrator, from version: Version) throws {
        // Nothing for now
    }
}

//
//  CollectionRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged

internal struct CollectionRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
    var description: String?
    var createdAt: Date = .now
    var updatedAt: Date = .now
}

extension CollectionRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "collection"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let name = Column(CodingKeys.name)
        static let description = Column(CodingKeys.description)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension CollectionRecord {
    static let mangaCollections = hasMany(MangaCollectionRecord.self)
    
    static let manga = hasMany(
        MangaRecord.self,
        through: mangaCollections,
        using: MangaCollectionRecord.manga
    ).order(MangaCollectionRecord.Columns.order)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: CollectionRecord.manga)
    }
}

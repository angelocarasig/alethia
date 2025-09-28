//
//  AuthorRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct AuthorRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    var name: String
}

extension AuthorRecord: FetchableRecord, MutablePersistableRecord {
    public static var databaseTableName: String {
        "author"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let name = Column(CodingKeys.name)
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension AuthorRecord {
    static let mangaAuthors = hasMany(MangaAuthorRecord.self)
    
    static let manga = hasMany(
        MangaRecord.self,
        through: mangaAuthors,
        using: MangaAuthorRecord.manga
    )
    
    // convenience request for fetching manga
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: AuthorRecord.manga)
    }
}

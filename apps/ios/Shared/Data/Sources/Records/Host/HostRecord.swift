//
//  HostRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct HostRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var name: String
    private(set) var author: String
    private(set) var url: URL
    private(set) var repository: URL
    
    private var official: Bool
}

extension HostRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "host"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        
        static let name = Column(CodingKeys.name)
        static let author = Column(CodingKeys.author)
        static let url = Column(CodingKeys.url)
        static let repository = Column(CodingKeys.repository)
        static let official = Column(CodingKeys.official)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension HostRecord {
    static let sources = hasMany(SourceRecord.self)
        .order(SourceRecord.Columns.name)
    
    var sources: QueryInterfaceRequest<SourceRecord> {
        request(for: HostRecord.sources)
    }
}

//
//  CoverRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct CoverRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var mangaId: MangaRecord.ID
    
    var isPrimary: Bool = false
    
    var localPath: URL
    var remotePath: URL
}

extension CoverRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "cover"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        
        static let isPrimary = Column(CodingKeys.isPrimary)
        
        static let localPath = Column(CodingKeys.localPath)
        static let remotePath = Column(CodingKeys.remotePath)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension CoverRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: CoverRecord.manga)
    }
}

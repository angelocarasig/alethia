//
//  ChapterRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct ChapterRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var originId: OriginRecord.ID
    private(set) var scanlatorId: ScanlatorRecord.ID
    
    var slug: String
    var title: String
    var number: Double
    var date: Date
    var url: URL
    var language: Domain.LanguageCode
    var progress: Double
    var lastReadAt: Date?
    
    var finished: Bool {
        progress >= 1
    }
}

extension ChapterRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "chapter"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let originId = Column(CodingKeys.originId)
        static let scanlatorId = Column(CodingKeys.scanlatorId)
        
        static let slug = Column(CodingKeys.slug)
        static let title = Column(CodingKeys.title)
        static let number = Column(CodingKeys.number)
        static let date = Column(CodingKeys.date)
        static let url = Column(CodingKeys.url)
        static let language = Column(CodingKeys.language)
        static let lastReadAt = Column(CodingKeys.lastReadAt)
        static let progress = Column(CodingKeys.progress)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension ChapterRecord {
    static let origin = belongsTo(OriginRecord.self)
    
    var origin: QueryInterfaceRequest<OriginRecord> {
        request(for: ChapterRecord.origin)
    }
}

extension ChapterRecord {
    static let scanlator = belongsTo(ScanlatorRecord.self)
    
    var scanlator: QueryInterfaceRequest<ScanlatorRecord> {
        request(for: ChapterRecord.scanlator)
    }
}

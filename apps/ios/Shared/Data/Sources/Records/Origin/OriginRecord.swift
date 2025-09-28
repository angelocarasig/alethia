//
//  OriginRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import GRDB
import Tagged
import Domain

internal struct OriginRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    private(set) var mangaId: MangaRecord.ID
    var sourceId: SourceRecord.ID?
    
    private(set) var slug: String
    private(set) var url: String
    var priority: Int
    var classification: Domain.Classification
    var status: Domain.Status
    
    var disconnected: Bool {
        sourceId == nil
    }
}

extension OriginRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "origin"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let mangaId = Column(CodingKeys.mangaId)
        static let sourceId = Column(CodingKeys.sourceId)
        
        static let slug = Column(CodingKeys.slug)
        static let url = Column(CodingKeys.url)
        static let priority = Column(CodingKeys.priority)
        static let classification = Column(CodingKeys.classification)
        static let status = Column(CodingKeys.status)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension OriginRecord {
    static let manga = belongsTo(MangaRecord.self)
    
    var manga: QueryInterfaceRequest<MangaRecord> {
        request(for: OriginRecord.manga)
    }
}

extension OriginRecord {
    static let chapters = hasMany(ChapterRecord.self)
    
    var chapters: QueryInterfaceRequest<ChapterRecord> {
        request(for: OriginRecord.chapters)
    }
}

extension OriginRecord {
    static let scanlatorPriorities = hasMany(OriginScanlatorPriorityRecord.self)
        .order(OriginScanlatorPriorityRecord.Columns.priority.asc)
    
    static let prioritizedScanlators = hasMany(
        ScanlatorRecord.self,
        through: scanlatorPriorities,
        using: OriginScanlatorPriorityRecord.scanlator
    )
    
    var prioritizedScanlators: QueryInterfaceRequest<ScanlatorRecord> {
        request(for: OriginRecord.prioritizedScanlators)
    }
}

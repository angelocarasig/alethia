//
//  SourceRecord.swift
//  Data
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation
import GRDB
import Tagged
import Domain

internal struct SourceRecord: Codable {
    typealias ID = Tagged<Self, Int64>
    private(set) var id: ID?
    
    private(set) var hostId: HostRecord.ID
    
    var slug: String
    var name: String
    var icon: URL
    var pinned: Bool = false
    var disabled: Bool = false
    
    var authType: Domain.AuthType?
}

extension SourceRecord: FetchableRecord, MutablePersistableRecord {
    static var databaseTableName: String {
        "source"
    }
    
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let hostId = Column(CodingKeys.hostId)
        
        static let slug = Column(CodingKeys.slug)
        static let name = Column(CodingKeys.name)
        static let icon = Column(CodingKeys.icon)
        static let pinned = Column(CodingKeys.pinned)
        static let disabled = Column(CodingKeys.disabled)
        
        static let authType = Column(CodingKeys.authType)
    }
    
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = ID(rawValue: inserted.rowID)
    }
}

extension SourceRecord {
    static let host = belongsTo(HostRecord.self)
    
    var host: QueryInterfaceRequest<HostRecord> {
        request(for: SourceRecord.host)
    }
}

extension SourceRecord {
    static let origins = hasMany(OriginRecord.self)
    
    var origins: QueryInterfaceRequest<OriginRecord> {
        request(for: SourceRecord.origins)
    }
}

// MARK: Search Associations
extension SourceRecord {
    static let searchConfig = hasOne(SearchConfigRecord.self)
    static let searchTags = hasMany(SearchTagRecord.self)
    static let searchPresets = hasMany(SearchPresetRecord.self)
    
    var searchConfig: QueryInterfaceRequest<SearchConfigRecord> {
        request(for: SourceRecord.searchConfig)
    }
    
    var searchTags: QueryInterfaceRequest<SearchTagRecord> {
        request(for: SourceRecord.searchTags)
    }
    
    var searchPresets: QueryInterfaceRequest<SearchPresetRecord> {
        request(for: SourceRecord.searchPresets)
    }
}

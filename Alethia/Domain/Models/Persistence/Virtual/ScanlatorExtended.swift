//
//  ScanlatorExtended.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/6/2025.
//

import Foundation
import GRDB

struct ScanlatorExtended: Decodable, FetchableRecord, Identifiable, Equatable {
    static func == (lhs: ScanlatorExtended, rhs: ScanlatorExtended) -> Bool {
        lhs.scanlator.id == rhs.scanlator.id
    }
    
    var id: Int64? {
        scanlator.id
    }
    
    var icon: String {
        underlyingSource?.icon ?? ""
    }
    
    // Core data
    var scanlator: Scanlator
    var priority: Int  // Priority within the origin
    var originId: Int64  // The origin this scanlator-priority relates to
    
    // Related entities
    var underlyingOrigin: Origin
    var underlyingSource: Source?
    var underlyingHost: Host?
}

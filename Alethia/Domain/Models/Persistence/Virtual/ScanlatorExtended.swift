//
//  ScanlatorExtended.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/6/2025.
//

import Foundation
import GRDB

struct ScanlatorExtended: Decodable, FetchableRecord {
    var id: Int64? {
        scanlator.id
    }
    
    var icon: String {
        underlyingSource?.icon ?? ""
    }
    
    var scanlator: Scanlator
    var underlyingOrigin: Origin
    var underlyingSource: Source?
    var underlyingHost: Host?
}

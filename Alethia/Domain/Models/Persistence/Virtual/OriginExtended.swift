//
//  OriginExtended.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/5/2025.
//

import Foundation
import GRDB

struct OriginExtended: Decodable, FetchableRecord, Identifiable, Equatable {
    static func == (lhs: OriginExtended, rhs: OriginExtended) -> Bool {
        lhs.origin.slug == rhs.origin.slug
    }
    
    var id: String {
        origin.slug
    }
    
    var origin: Origin
    var source: Source?
    
    var hostName: String
    var hostAuthor: String
    
    var chapterCount: Int
    
    var sourceName: String {
        source?.name ?? "Unknown Source"
    }
    
    var sourceHost: String {
        "@\(hostName)/\(hostAuthor)".lowercased()
    }
    
    var sourceIcon: String {
        source?.icon ?? ""
    }
}

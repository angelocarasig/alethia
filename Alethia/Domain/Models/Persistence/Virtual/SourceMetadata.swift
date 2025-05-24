//
//  SourceMetadata.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/5/2025.
//

import Foundation
import GRDB

// Includes metadata as well such as host title/author

struct SourceMetadata: Decodable, FetchableRecord, Equatable {
    static func == (lhs: SourceMetadata, rhs: SourceMetadata) -> Bool {
        (lhs.source.id != nil && rhs.source.id != nil) &&
        (lhs.source.id == rhs.source.id)
    }
    
    var source: Source
    var hostName: String
    var hostAuthor: String
    var hostWebsite: String
}

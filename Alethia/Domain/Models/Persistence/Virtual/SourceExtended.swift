//
//  SourceExtended.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Foundation
import GRDB

struct SourceExtended: Decodable, FetchableRecord, Equatable {
    static func == (lhs: SourceExtended, rhs: SourceExtended) -> Bool {
        (lhs.source.id != nil && rhs.source.id != nil) &&
        (lhs.source.id == rhs.source.id)
    }
    
    var host: Host
    var source: Source
    var routes: [SourceRoute]
}

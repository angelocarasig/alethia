//
//  CollectionExtended.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

struct CollectionExtended: Decodable, FetchableRecord, Identifiable, Equatable {
    var id: String {
        collection.id?.description ?? collection.name
    }
    
    static func == (lhs: CollectionExtended, rhs: CollectionExtended) -> Bool {
        lhs.collection.id == rhs.collection.id
    }
    
    var collection: Collection
    var itemCount: Int
}

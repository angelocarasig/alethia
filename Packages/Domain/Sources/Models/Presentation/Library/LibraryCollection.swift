//
//  LibraryCollection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

public extension Domain.Models.Presentation {
    struct LibraryCollection: Decodable, FetchableRecord {
        public let collection: Domain.Models.Persistence.Collection
        public let itemCount: Int
    }
}

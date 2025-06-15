//
//  LibraryCollection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Presentation {
    struct LibraryCollection: Decodable {
        public let collection: Domain.Models.Persistence.Collection
        public let itemCount: Int
    }
}

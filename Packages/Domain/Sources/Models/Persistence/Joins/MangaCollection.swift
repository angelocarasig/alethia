//
//  MangaCollection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    // a manga can have many collections
    // a collection can have many manga
    struct MangaCollection: Codable, Sendable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated collection id
        public var collectionId: Int64
        
        public init(
            mangaId: Int64,
            collectionId: Int64
        ) {
            self.mangaId = mangaId
            self.collectionId = collectionId
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case mangaId
            case collectionId
        }
    }
}

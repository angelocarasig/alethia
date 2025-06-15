//
//  MangaAuthor.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    // a manga can have many authors
    // an author can have many manga
    struct MangaAuthor: Codable, Sendable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated author id
        public var authorId: Int64
        
        public init(
            mangaId: Int64,
            authorId: Int64
        ) {
            self.mangaId = mangaId
            self.authorId = authorId
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case mangaId
            case authorId
        }
    }
}

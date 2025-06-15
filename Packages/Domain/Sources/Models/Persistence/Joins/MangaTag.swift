//
//  MangaTag.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// a manga can have many tags
    /// a tag can have many manga
    struct MangaTag: Codable, Sendable {
        // MARK: - Properties
        
        /// joiner to associated manga id
        public var mangaId: Int64
        
        /// joiner to associated tag id
        public var tagId: Int64
        
        public init(
            mangaId: Int64,
            tagId: Int64
        ) {
            self.mangaId = mangaId
            self.tagId = tagId
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case mangaId
            case tagId
        }
    }
}

//
//  Cover.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents a cover image for a manga
    struct Cover: Identifiable, Codable, Sendable, Equatable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// associated manga for this cover
        public var mangaId: Int64
        
        /// whether this cover is the active one
        public var active: Bool
        
        /// url to the cover image
        public var url: String
        
        /// local file path to the cached cover
        public var path: String
        
        public init(
            id: Int64? = nil,
            mangaId: Int64,
            active: Bool,
            url: String,
            path: String
        ) {
            self.id = id
            self.mangaId = mangaId
            self.active = active
            self.url = url
            self.path = path
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case mangaId
            case active
            case url
            case path
        }
    }
}

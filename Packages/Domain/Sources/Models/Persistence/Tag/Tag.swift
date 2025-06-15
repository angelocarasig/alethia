//
//  Tag.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents a tag for a manga
    struct Tag: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of the tag
        public var name: String
        
        public init(
            id: Int64? = nil,
            name: String
        ) {
            self.id = id
            self.name = name
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case name
        }
    }
}

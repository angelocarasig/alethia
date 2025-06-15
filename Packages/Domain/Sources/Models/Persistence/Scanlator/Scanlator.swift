//
//  Scanlator.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents a scanlator group
    ///
    /// metadata only includes name as other properties are difficult to track
    ///
    /// priority values are defined in a separate `Channel` model as each scanlator
    /// may be preferred over another based on each origin/manga
    struct Scanlator: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of scanlation group
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

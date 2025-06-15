//
//  SourceRoute.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents a unique route for a source
    ///
    /// examples include: 'Popular', 'Top', Recently Updated', 'New', etc.
    struct SourceRoute: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// parent source the route belongs to
        public var sourceId: Int64
        
        /// display name of the route
        public var name: String
        
        /// url-based path identifier for the route - used when constructing a fetch url
        public var path: String
        
        public init(
            id: Int64? = nil,
            sourceId: Int64,
            name: String,
            path: String
        ) {
            self.id = id
            self.sourceId = sourceId
            self.name = name
            self.path = path
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case sourceId
            case name
            case path
        }
    }
}

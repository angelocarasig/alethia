//
//  Source.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents an individual source provided by the underlying host
    struct Source: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// parent host the source belongs to
        public var hostId: Int64
        
        /// display name of the source
        public var name: String
        
        /// path to the icon
        public var icon: String
        
        /// url-based path identifier used when constructing a fetch url
        public var path: String
        
        /// url to the source website
        ///
        /// requirement to ensure visibility of original provider
        /// and can be used as reference for mismatches/inconsistencies
        /// within the app
        public var website: String
        
        /// description of source
        ///
        /// often this is just the <meta> description tag from the website
        public var description: String
        
        /// determines if the source is pinned
        ///
        /// used so that displayed sources are sorted alphabetically with
        /// pinned sources at the top
        public var pinned: Bool = false
        
        /// determines if the source is disabled
        ///
        /// disabled sources are placed either at the bottom of lists or
        /// not displayed at all.
        /// disabled sources are not used in any content refreshes, not
        /// displayed in any search results and any origins belonging to
        /// the disabled source do not display their chapters if any.
        public var disabled: Bool = false
        
        public init(
            id: Int64? = nil,
            hostId: Int64,
            name: String,
            icon: String,
            path: String,
            website: String,
            description: String,
            pinned: Bool = false,
            disabled: Bool = false
        ) {
            self.id = id
            self.hostId = hostId
            self.name = name
            self.icon = icon
            self.path = path
            self.website = website
            self.description = description
            self.pinned = pinned
            self.disabled = disabled
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case hostId
            case name
            case icon
            case path
            case website
            case description
            case pinned
            case disabled
        }
    }
}

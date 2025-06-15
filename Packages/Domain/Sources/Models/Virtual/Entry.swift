//
//  Entry.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

internal typealias Entry = Domain.Models.Virtual.Entry

public extension Domain.Models.Virtual {
    struct Entry: Identifiable, Hashable, Decodable, Sendable {
        // MARK: - Properties
        
        /// underlying manga id if it exists
        ///
        /// optional as it can be initialized via
        /// - local library/db, where it does exist for sure
        /// - source route content, where it comes from a remote server
        public var mangaId: Int64?
        
        /// underlying source id if it exists
        ///
        /// optional as it can be initialized via
        /// - local library/db, which retrieves the highest priority origin's sourceId
        /// - remote server, either from a search/source route content to distinguish
        /// how each entry is unique in these views
        public var sourceId: Int64?
        
        /// title of entry
        public var title: String
        
        /// a unique identifier used for building fetch url
        ///
        /// maps from origin's slug, which is used in matching algorithms to determine
        /// whether in library/partial match etc.
        public var slug: String
        
        /// cover remote url
        public var cover: String
        
        /// fetch url to retrieve details content from the remote server, or nil if
        /// coming from a detached source
        public var fetchUrl: String?
        
        /// unread count for the entry's underlying manga chapter list count
        public var unread: Int
        
        /// match type
        public var match: Domain.Models.Enums.EntryMatch
        
        // MARK: - Internal
        /// these properties are required for in-library filtering and are mirrors of default
        /// manga internal properties
        
        public var inLibrary: Bool
        public var addedAt: Date
        public var updatedAt: Date
        public var lastReadAt: Date?
        
        public enum CodingKeys: String, CodingKey {
            case mangaId
            case sourceId
            case title
            case slug
            case cover
            case fetchUrl
            case unread
            case match
            case inLibrary
            case addedAt
            case updatedAt
            case lastReadAt
        }
        
        public init(
            mangaId: Int64? = nil,
            sourceId: Int64? = nil,
            title: String,
            slug: String,
            cover: String,
            fetchUrl: String? = nil,
            unread: Int = 0,
            match: Domain.Models.Enums.EntryMatch = .none,
            inLibrary: Bool,
            addedAt: Date = .distantPast,
            updatedAt: Date = .distantPast,
            lastReadAt: Date? = nil
        ) {
            self.mangaId = mangaId
            self.sourceId = sourceId
            self.title = title
            self.slug = slug
            self.cover = cover
            self.fetchUrl = fetchUrl
            self.unread = unread
            self.match = match
            self.inLibrary = inLibrary
            self.addedAt = addedAt
            self.updatedAt = updatedAt
            self.lastReadAt = lastReadAt
        }
        
        // Custom decoder to handle NULLs from database
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            mangaId = try container.decodeIfPresent(Int64.self, forKey: .mangaId)
            sourceId = try container.decodeIfPresent(Int64.self, forKey: .sourceId)
            title = try container.decode(String.self, forKey: .title)
            
            // Handle nullable slug - default to empty string
            slug = try container.decodeIfPresent(String.self, forKey: .slug) ?? ""
            
            // Handle nullable cover - default to empty string
            cover = try container.decodeIfPresent(String.self, forKey: .cover) ?? ""
            
            fetchUrl = try container.decodeIfPresent(String.self, forKey: .fetchUrl)
            unread = try container.decodeIfPresent(Int.self, forKey: .unread) ?? 0
            
            // Handle match - default to .none if not present
            if let matchString = try container.decodeIfPresent(String.self, forKey: .match),
               let matchValue = Domain.Models.Enums.EntryMatch(rawValue: matchString) {
                match = matchValue
            } else {
                match = .none
            }
            
            inLibrary = try container.decode(Bool.self, forKey: .inLibrary)
            addedAt = try container.decode(Date.self, forKey: .addedAt)
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
            lastReadAt = try container.decodeIfPresent(Date.self, forKey: .lastReadAt)
        }
    }
}

// MARK: - Computed
public extension Entry {
    var id: String {
        // coming from a source - use the fetch url
        if let fetchUrl = fetchUrl {
            return fetchUrl
        }
        
        // coming from library - use library related props
        else if let mangaId = mangaId {
            return "manga-\(mangaId)-\(match)"
        }
        
        // who knows when this would happen but as an extra measure
        else if let sourceId = sourceId {
            return "source-\(sourceId)-\(slug)"
        }
        
        // fallback which shouldn't generally happen
        else {
            return "unknown-\(title)-\(slug)"
        }
    }
}

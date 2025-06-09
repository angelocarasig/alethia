//
//  Entry.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

// MARK: - Entry Model

struct Entry: Codable, Hashable, Identifiable {
    // MARK: Properties
    
    var mangaId: Int64?
    var sourceId: Int64?
    var title: String
    var slug: String
    var cover: String?
    var fetchUrl: String?
    
    // Properties needed for querying
    var inLibrary: Bool
    var addedAt: Date = .distantPast
    var updatedAt: Date = .distantPast
    var lastReadAt: Date? = nil
    
    // Transient state
    var match: EntryMatch = .none
    var unread: Int
    
    // MARK: Initialization
    
    init(
        mangaId: Int64? = nil,
        sourceId: Int64? = nil,
        title: String,
        slug: String,
        cover: String? = nil,
        fetchUrl: String? = nil,
        inLibrary: Bool = false,
        unread: Int = -1,
        match: EntryMatch? = EntryMatch.none
    ) {
        self.mangaId = mangaId
        self.sourceId = sourceId
        self.title = title
        self.slug = slug
        self.cover = cover
        self.fetchUrl = fetchUrl
        self.inLibrary = inLibrary
        self.unread = unread
        self.match = match ?? .none
    }
}

// MARK: - Identifiers

extension Entry {
    var id: String {
        fetchUrl ?? // fetchUrl is a stable unique value - may not exist if source not present
        "\(mangaId ?? sourceId ?? -1)-\(title)-\(unread)"
    }
    
    /// A computed property that represents the unique identifier for a transition.
    /// This identifier is used to track and manage transitions within the system.
    var transitionId: String {
        id
    }
    
    /// A computed property that returns the identifier of the source view associated with this entry.
    /// This identifier is typically used to track or reference the view from which the entry originates.
    var sourceViewId: String {
        "\(id)-\(match)"
    }
    
    /// Definitely exist since they're in library
    var libraryViewId: String {
        "\(mangaId!)"
    }
}

// MARK: - Queue Operation Support

extension Entry: QueueOperationIdentifiable {
    var queueOperationId: String {
        "manga-\(mangaId ?? -1)"
    }
}

// MARK: - Database Support

extension Entry {
    private enum CodingKeys: String, CodingKey {
        case mangaId, sourceId, title, slug, cover, fetchUrl, unread
        case inLibrary, addedAt, updatedAt, lastReadAt
    }
}

// MARK: - GRDB TableRecord

extension Entry: TableRecord {
    static let databaseTableName = "entry" // References the view created in Database+Views
    
    enum Columns {
        static let mangaId = Column(CodingKeys.mangaId)
        static let sourceId = Column(CodingKeys.sourceId)
        static let title = Column(CodingKeys.title)
        static let slug = Column(CodingKeys.slug)
        static let cover = Column(CodingKeys.cover)
        static let fetchUrl = Column(CodingKeys.fetchUrl)
        
        static let inLibrary = Column(CodingKeys.inLibrary)
        static let addedAt = Column(CodingKeys.addedAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let lastReadAt = Column(CodingKeys.lastReadAt)
        
        static let unread = Column(CodingKeys.unread)
    }
}

// MARK: - GRDB FetchableRecord

extension Entry: FetchableRecord {}

// MARK: - Entry Match Type

enum EntryMatch {
    // Does not exist in library at all
    case none
    
    // Same title
    case partial
    
    // Exact ID
    case exact
}

// MARK: - Recommended Entries

struct RecommendedEntries {
    // Similar in your library
    let withSimilarTags: [Entry]
    
    // Others in same collection
    let fromSameCollection: [Entry]
    
    // Authors other works
    let otherWorksByAuthor: [Entry]
    
    // Scanlator's other series
    let otherSeriesByScanlator: [Entry]
}

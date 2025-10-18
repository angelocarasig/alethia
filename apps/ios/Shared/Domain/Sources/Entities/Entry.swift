//
//  Entry.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Entry: Codable, Sendable, Hashable {
    /// when null, entry is from external search and not yet matched
    public let mangaId: Int64?
    
    public let sourceId: Int64?
    
    public let slug: String

    public let title: String

    /// location to the remote resource
    public let cover: URL
    
    public let state: EntryState
    
    /// unread chapter count - only populated for library queries, not for findMatches
    public let unread: Int
    
    public init(
        mangaId: Int64? = nil,
        sourceId: Int64? = nil,
        slug: String,
        title: String,
        cover: URL,
        state: EntryState,
        unread: Int = 0
    ) {
        self.mangaId = mangaId
        self.sourceId = sourceId
        self.slug = slug
        self.title = title
        self.cover = cover
        self.state = state
        self.unread = unread
    }
}

public enum EntryState: Codable, Sendable {
    case exactMatch                        // slug matched, same source
    case crossSourceMatch                  // slug matched, different source
    case titleMatchSameSource             // single title match, same source
    case titleMatchSameSourceAmbiguous    // multiple title matches, same source
    case titleMatchDifferentSource        // title match(es), different source(s)
    case matchVerificationFailed          // error during matching
    case noMatch                          // no match found
}

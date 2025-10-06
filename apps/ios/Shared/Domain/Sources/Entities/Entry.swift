//
//  Entry.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Entry: Codable, Sendable {
    /// When null most likely
    public let mangaId: Int64?
    
    public let sourceId: Int64?
    
    public let slug: String

    public let title: String

    /// Location to the remote resource
    public let cover: URL
    
    public let state: EntryState
    
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
    case fullMatch
    case partialMatch
    case noMatch
}

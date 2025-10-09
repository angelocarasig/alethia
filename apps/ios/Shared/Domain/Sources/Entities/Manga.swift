//
//  Manga.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Manga: Sendable {
    public let id: Int64
    
    // main metadata
    public let title: String
    public let authors: [String]
    public let synopsis: AttributedString
    public let alternativeTitles: [String]
    public let tags: [String]
    public let covers: [URL]
    
    // relational
    public let origins: [Origin]
    public let chapters: [Chapter]
    
    // config
    public let inLibrary: Bool
    public let addedAt: Date
    public let updatedAt: Date
    public let lastFetchedAt: Date
    public let lastReadAt: Date
    
    public let orientation: Orientation
    public let showAllChapters: Bool
    public let showHalfChapters: Bool
    
    public init(
        id: Int64,
        title: String,
        authors: [String],
        synopsis: AttributedString,
        alternativeTitles: [String],
        tags: [String],
        covers: [URL],
        origins: [Origin],
        chapters: [Chapter],
        inLibrary: Bool,
        addedAt: Date,
        updatedAt: Date,
        lastFetchedAt: Date,
        lastReadAt: Date,
        orientation: Orientation,
        showAllChapters: Bool,
        showHalfChapters: Bool
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        
        // re-parse synopsis as markdown to ensure proper formatting
        let plainText = String(synopsis.characters)
        if let parsed = try? AttributedString(
            markdown: plainText,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            self.synopsis = parsed
        } else {
            self.synopsis = synopsis
        }
        
        self.alternativeTitles = alternativeTitles
        self.tags = tags
        self.covers = covers
        self.origins = origins
        self.chapters = chapters
        self.inLibrary = inLibrary
        self.addedAt = addedAt
        self.updatedAt = updatedAt
        self.lastFetchedAt = lastFetchedAt
        self.lastReadAt = lastReadAt
        self.orientation = orientation
        self.showAllChapters = showAllChapters
        self.showHalfChapters = showHalfChapters
    }
}

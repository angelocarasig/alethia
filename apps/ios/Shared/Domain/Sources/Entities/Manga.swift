//
//  Manga.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Manga {
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
}

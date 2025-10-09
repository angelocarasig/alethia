//
//  Chapter.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Chapter: Sendable {
    public let id: Int64
    
    public let slug: String
    
    public let title: String
    
    public let number: Double
    
    public let date: Date
    
    public let scanlator: String
    
    public let language: LanguageCode
    
    public let url: String
    
    /// refers to its parent source's icon
    public let icon: URL?
    
    public let progress: Double
    
    public var finished: Bool {
        progress >= 1
    }
    
    public var downloaded: Bool {
        false
    }
    
    public init(
        id: Int64,
        slug: String,
        title: String,
        number: Double,
        date: Date,
        scanlator: String,
        language: LanguageCode,
        url: String,
        icon: URL?,
        progress: Double
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.number = number
        self.date = date
        self.scanlator = scanlator
        self.language = language
        self.url = url
        self.icon = icon
        self.progress = progress
    }
}

//
//  Details.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Virtual {
    /// all relevant models joined with an underlying `Manga` model to be used in displaying details
    struct Details: Decodable, Sendable {
        // MARK: - Core
        /// main manga object
        public let manga: Domain.Models.Persistence.Manga
        
        // MARK: - Metadata
        /// titles for the associated manga
        public let titles: [Domain.Models.Persistence.Title]
        
        /// authors for the associated manga
        public let authors: [Domain.Models.Persistence.Author]
        
        /// covers for the associated manga
        public let covers: [Domain.Models.Persistence.Cover]
        
        /// tags for the associated manga
        public let tags: [Domain.Models.Persistence.Tag]
        
        // MARK: - Organization
        /// collections for the associated manga
        public let collections: [Domain.Models.Persistence.Collection]
        
        // MARK: - Content
        public let sources: [SourceInfo]
        public let chapters: [ChapterInfo]
    }
}

public extension Domain.Models.Virtual.Details {
    /// represents an origin with its source hierarchy and available scanlators
    struct SourceInfo: Decodable, Sendable {
        public let origin: Domain.Models.Persistence.Origin
        public let source: Domain.Models.Persistence.Source?
        public let host: Domain.Models.Persistence.Host?
        
        public let scanlators: [ScanlatorInfo]
    }
    
    /// represents a scanlator with their priority for a specific origin
    struct ScanlatorInfo: Decodable, Sendable {
        public let scanlator: Domain.Models.Persistence.Scanlator
        public let priority: Int
    }
    
    /// represents a chapter with its full context including source and scanlator
    struct ChapterInfo: Decodable, Sendable {
        public let chapter: Domain.Models.Persistence.Chapter
        public let scanlator: Domain.Models.Persistence.Scanlator
        
        public let origin: Domain.Models.Persistence.Origin
        public let source: Domain.Models.Persistence.Source?
        public let host: Domain.Models.Persistence.Host?
    }
}

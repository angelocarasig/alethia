//
//  Details.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

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
        
        public init(
            manga: Domain.Models.Persistence.Manga,
            titles: [Domain.Models.Persistence.Title],
            authors: [Domain.Models.Persistence.Author],
            covers: [Domain.Models.Persistence.Cover],
            tags: [Domain.Models.Persistence.Tag],
            collections: [Domain.Models.Persistence.Collection],
            sources: [SourceInfo],
            chapters: [ChapterInfo]
        ) {
            self.manga = manga
            self.titles = titles
            self.authors = authors
            self.covers = covers
            self.tags = tags
            self.collections = collections
            self.sources = sources
            self.chapters = chapters
        }
    }
}

public extension Domain.Models.Virtual.Details {
    /// represents an origin with its source hierarchy and available scanlators
    struct SourceInfo: Decodable, Sendable {
        public let origin: Domain.Models.Persistence.Origin
        public let source: Domain.Models.Persistence.Source?
        public let host: Domain.Models.Persistence.Host?
        
        public let scanlators: [ScanlatorInfo]
        
        public init(
            origin: Domain.Models.Persistence.Origin,
            source: Domain.Models.Persistence.Source?,
            host: Domain.Models.Persistence.Host?,
            scanlators: [ScanlatorInfo]
        ) {
            self.origin = origin
            self.source = source
            self.host = host
            self.scanlators = scanlators
        }
    }
    
    /// represents a scanlator with their priority for a specific origin
    struct ScanlatorInfo: Decodable, Sendable {
        public let scanlator: Domain.Models.Persistence.Scanlator
        public let priority: Int
        
        public init(
            scanlator: Domain.Models.Persistence.Scanlator,
            priority: Int
        ) {
            self.scanlator = scanlator
            self.priority = priority
        }
    }
    
    /// represents a chapter with its full context including source and scanlator
    struct ChapterInfo: Decodable, Sendable {
        public let chapter: Domain.Models.Persistence.Chapter
        public let scanlator: Domain.Models.Persistence.Scanlator
        
        public let origin: Domain.Models.Persistence.Origin
        public let source: Domain.Models.Persistence.Source?
        public let host: Domain.Models.Persistence.Host?
        
        public init(
            chapter: Domain.Models.Persistence.Chapter,
            scanlator: Domain.Models.Persistence.Scanlator,
            origin: Domain.Models.Persistence.Origin,
            source: Domain.Models.Persistence.Source?,
            host: Domain.Models.Persistence.Host?
        ) {
            self.chapter = chapter
            self.scanlator = scanlator
            self.origin = origin
            self.source = source
            self.host = host
        }
    }
}

// MARK: - Domain-specific functions
public extension Domain.Models.Virtual.Details {
    /// Converts details to an entry with a specific source ID.
    /// Used when resolving collisions where multiple manga match the same entry.
    ///
    /// - Parameters:
    ///   - sourceId: The source ID to use for the entry
    ///   - originalEntry: The original entry to preserve slug and cover information from
    /// - Returns: A resolved entry with exact match
    func toEntry(sourceId: Int64, from originalEntry: Domain.Models.Virtual.Entry) -> Domain.Models.Virtual.Entry {
        let matchingSource = sources.first { $0.source?.id == sourceId }
        
        return Domain.Models.Virtual.Entry(
            mangaId: manga.id,
            sourceId: sourceId,
            title: manga.title,
            slug: matchingSource?.origin.slug ?? "",
            cover: covers.first { $0.active }?.url ?? "",
            fetchUrl: buildFetchUrl(for: matchingSource),
            unread: calculateUnreadCount(),
            match: .exact,
            inLibrary: manga.inLibrary,
            addedAt: manga.addedAt,
            updatedAt: manga.updatedAt,
            lastReadAt: manga.lastReadAt
        )
    }
    
    /// Builds the fetch URL for a source info
    private func buildFetchUrl(for sourceInfo: SourceInfo?) -> String? {
        guard let sourceInfo = sourceInfo,
              let host = sourceInfo.host,
              let source = sourceInfo.source else {
            return nil
        }
        
        let baseUrl = host.baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let sourcePath = source.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let slug = sourceInfo.origin.slug
        
        return "\(baseUrl)/\(sourcePath)/manga/\(slug)"
    }
    
    /// Calculates unread chapter count based on current manga settings
    private func calculateUnreadCount() -> Int {
        chapters
            .filter { info in
                let chapter = info.chapter
                let isUnread = chapter.progress < 1.0
                let shouldShow = manga.showHalfChapters || chapter.number.truncatingRemainder(dividingBy: 1) == 0
                return isUnread && shouldShow
            }
            .count
    }
}

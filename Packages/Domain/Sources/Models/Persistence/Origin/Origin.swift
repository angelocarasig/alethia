//
//  Origin.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Persistence {
    /// acts as joining aggregator between a manga and its content source
    ///
    /// - multi-source aggregation support via the origin
    /// - offers source-specific metadata that can differ between different sources
    struct Origin: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// underlying source origin belongs to
        ///
        /// nullable so that deleting a host does not remove the
        /// content and instead treats the origin as 'detached'
        ///
        /// when this occurs, no content can be fetched, no chapters
        /// can be read, etc. and will be prompted to attach the manga
        /// to a proper source
        ///
        /// exception are for downloaded chapters which is expected
        /// behaviour.
        public var sourceId: Int64?
        
        /// required id to the underlying manga the origin is associated with
        public var mangaId: Int64
        
        /// a unique identifier used for building fetch url
        ///
        /// also used in matching algorithms based on `Entry` slug
        /// to determine whether in library/partial match etc.
        public var slug: String
        
        /// URL to the content via its source
        ///
        /// can be useful artifact for a detached source and figuring
        /// out what the source was before it got detached.
        public var url: String
        
        /// referer used for requests to chapter page content
        public var referer: String
        
        /// classification of the origin
        public var classification: Domain.Models.Enums.Classification
        
        /// publication status of the origin
        public var status: Domain.Models.Enums.PublishStatus
        
        /// alleged date the source material was created from the given source
        public var createdAt: Date
        
        /// priority-based algorithm to determine how the unified chapter list
        /// is returned where priority ∈ ℤ, 0 ≤ priority < ∞
        ///
        /// lower values have higher precedence (0 = highest priority).
        public var priority: Int = -1
        
        public init(
            id: Int64? = nil,
            sourceId: Int64,
            mangaId: Int64,
            slug: String,
            url: String,
            referer: String,
            classification: Domain.Models.Enums.Classification,
            status: Domain.Models.Enums.PublishStatus,
            createdAt: Date,
            priority: Int
        ) {
            self.id = id
            self.sourceId = sourceId
            self.mangaId = mangaId
            
            self.slug = slug
            self.url = url
            self.referer = referer
            self.classification = classification
            self.status = status
            self.createdAt = createdAt
            
            self.priority = priority
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case sourceId
            case mangaId
            case slug
            case url
            case referer
            case classification
            case status
            case createdAt
            case priority
        }
    }
}

//
//  Origin.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import GRDB

internal typealias Origin = Domain.Models.Persistence.Origin

public extension Domain.Models.Persistence {
    /// acts as joining aggregator between a manga and its content source
    ///
    /// - multi-source aggregation support via the origin
    /// - offers source-specific metadata that can differ between different sources
    struct Origin: Identifiable, Codable {
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
        
        init(
            id: Int64? = nil,
            sourceId: Int64,
            mangaId: Int64,
            slug: String,
            url: String,
            referer: String,
            classification: Classification,
            status: PublishStatus,
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
    }
}

// MARK: - Database Conformance
extension Origin: FetchableRecord, PersistableRecord {}

extension Origin: TableRecord {
    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let sourceId = Column(CodingKeys.sourceId)
        public static let mangaId = Column(CodingKeys.mangaId)
        
        public static let slug = Column(CodingKeys.slug)
        public static let url = Column(CodingKeys.url)
        public static let referer = Column(CodingKeys.referer)
        public static let classification = Column(CodingKeys.classification)
        public static let status = Column(CodingKeys.status)
        public static let createdAt = Column(CodingKeys.createdAt)
        
        public static let priority = Column(CodingKeys.priority)
    }
}

// MARK: - Database Relations
extension Origin {
    // belongs to a single manga
    static let manga = belongsTo(Domain.Models.Persistence.Manga.self)
    
    // belongs to a single (optional) source
    static let source = belongsTo(Domain.Models.Persistence.Source.self)
    var source: QueryInterfaceRequest<Domain.Models.Persistence.Source> {
        request(for: Domain.Models.Persistence.Origin.source)
    }
    
    // has many chapters
    static let chapters = hasMany(Domain.Models.Persistence.Chapter.self)
    var chapters: QueryInterfaceRequest<Domain.Models.Persistence.Chapter> {
        request(for: Domain.Models.Persistence.Origin.chapters)
    }
    
    // has many channels
    static let channels = hasMany(Domain.Models.Persistence.Channel.self)
    
    // has many scanlators
    static let scanlators = hasMany(Domain.Models.Persistence.Scanlator.self, through: channels, using: Domain.Models.Persistence.Channel.scanlator)
}

// MARK: - Database Table Definition + Migrations
extension Origin: Domain.Models.Database.DatabaseMigratable {
    public static func createTable(db: Database) throws {
        try db.create(table: databaseTableName, body: { t in
            // ids
            t.autoIncrementedPrimaryKey(Columns.id.name)
            t.column(Columns.sourceId.name, .integer)
                .references(Source.databaseTableName, onDelete: .setNull)
            t.column(Columns.mangaId.name, .integer)
                .notNull()
                .references(Manga.databaseTableName, onDelete: .cascade)
            
            // properties
            t.column(Columns.slug.name, .text).notNull()
            t.column(Columns.url.name, .text).notNull()
            t.column(Columns.referer.name, .text).notNull()
            t.column(Columns.classification.name, .text).notNull()
            t.column(Columns.status.name, .text).notNull()
            t.column(Columns.createdAt.name, .date).notNull()
            
            // control
            t.column(Columns.priority.name, .integer).notNull()
        })
    }
    
    public static func migrate(with migrator: inout DatabaseMigrator, from version: Domain.Models.Database.Version) throws {
        // nothing for now
    }
}

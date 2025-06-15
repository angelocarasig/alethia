//
//  Chapter.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Core
import Foundation

public extension Domain.Models.Persistence {
    /// represents a single chapter within a manga series and acts as the atomic units of
    /// content that readers consume.
    ///
    /// each chapter belongs to a specific origin (manga on a source) and is provided by a
    /// scanlator group.
    ///
    /// the same logical chapter (e.g., chapter 10) may exist multiple times with
    /// different origins or scanlators, and have related models to determine priority in
    /// what chapters to display in a unified list
    struct Chapter: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// associated origin for this chapter
        public var originId: Int64
        
        /// associated scanlator for this chapter
        public var scanlatorId: Int64
        
        /// title of the chapter
        public var title: String
        
        /// unique chapter identifier used for building fetch url for this chapter's pages
        public var slug: String
        
        /// number of the chapter
        public var number: Double
        
        /// date this chapter was released
        ///
        /// this value is not really a global indicator, it depends on a few considerations
        /// - the scanlator who published this
        /// - the associated origin for this
        /// - the source based on the origin (some sources have higher scans but released slower)
        public var date: Date
        
        /// read progress for the chapter
        public var progress: Double = 0.0
        
        /// path to the .cbz for this chapter if any
        public var localPath: String? = nil
        
        public init(
            id: Int64? = nil,
            originId: Int64,
            scanlatorId: Int64,
            title: String,
            slug: String,
            number: Double,
            date: Date,
            progress: Double,
            localPath: String? = nil
        ) {
            self.id = id
            self.originId = originId
            self.scanlatorId = scanlatorId
            
            self.title = title
            self.slug = slug
            self.number = number
            self.date = date
            
            self.progress = progress
            self.localPath = localPath
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case originId
            case scanlatorId
            case title
            case slug
            case number
            case date
            case progress
            case localPath
        }
    }
}

// MARK: - Computed
extension Domain.Models.Persistence.Chapter: CustomStringConvertible {
    /// determines if the chapter has been read or not
    var read: Bool {
        self.progress == 1.0
    }
    
    /// determines if the chapter has been downloaded or not
    var downloaded: Bool {
        self.localPath != nil
    }
    
    /// string description of chapter
    public var description: String {
        "Chapter \(self.number.toString()) \(title.isEmpty ? "" : " - \(title)")"
    }
}

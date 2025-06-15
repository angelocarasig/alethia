//
//  Manga.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Persistence {
    /// a manga series
    ///
    /// the main unit of the app really
    struct Manga: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// title of manga
        public var title: String
        
        /// synopsis of manga
        ///
        /// using `syonpsis` keyword instead of description to prevent
        /// potential conflicts just in internal naming conventions
        public var synopsis: String
        
        /// date the manga was added at
        public var addedAt: Date = Date()
        
        /// date the manga was last updated
        ///
        /// this property more specifically is whenever a new chapter for
        /// the manga is actually inserted, not when it was last refreshed
        public var updatedAt: Date = Date()
        
        /// date the manga was last read at
        public var lastReadAt: Date? = nil
        
        /// whether manga is in the library or not
        public var inLibrary: Bool = false
        
        /// reading orientation of the manga
        ///
        /// defaults to the `Default` orientation, which in this case
        /// will be inferred whether to show a horizontal/vertical orientation
        ///
        /// any subsequent updates can and should only be out of the 4 non-default
        /// options which essentially acts as an override over the inferring value
        public var orientation: Domain.Models.Enums.Orientation = .Default
        
        /// control what chapters to show - whether to show all chapters
        public var showAllChapters: Bool = false
        
        /// control what chapters to show - whether to show non-integer chapters
        ///
        /// more specifically:
        /// - where chapter.number ∈ ℤ (e.g., 1, 2, 3)
        /// - chapter.number ∈ ℝ\ℤ (e.g., 1.5, 2.1, 3.9)
        public var showHalfChapters: Bool = true
        
        public init(title: String, synopsis: String) {
            self.title = title
            self.synopsis = synopsis
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case title
            case synopsis
            case addedAt
            case updatedAt
            case lastReadAt
            case inLibrary
            case orientation
            case showAllChapters
            case showHalfChapters
        }
    }
}

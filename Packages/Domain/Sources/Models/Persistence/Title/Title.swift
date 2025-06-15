//
//  Title.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents a title for a manga and generally considered as alternative titles
    struct Title: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// associated manga for this title
        public var mangaId: Int64
        
        /// alternative title for the manga
        public var title: String
        
        public init(
            id: Int64? = nil,
            mangaId: Int64,
            title: String
        ) {
            self.id = id
            self.mangaId = mangaId
            self.title = title
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case mangaId
            case title
        }
    }
}

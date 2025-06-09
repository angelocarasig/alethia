//
//  DatabaseProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB
import Combine

final class DatabaseProvider {
    public let version: Version = Version(1, 0, 1)
    
    public let models: [DatabaseMigratable.Type] = [
        // MARK: - Source Infrastructure (No dependencies)
        Host.self,
        Source.self,
        SourceRoute.self,
        
        // MARK: - Global Entities (No dependencies)
        Author.self,
        Tag.self,
        Collection.self,
        Scanlator.self,
        
        // MARK: - Core Entities (Depends on above)
        Manga.self,
        Origin.self,
        Chapter.self, // Depends on Origin and Scanlator
        
        // MARK: - Manga Relationships (Depends on Manga)
        Title.self,
        Cover.self,
        
        // MARK: - Join Tables (Depends on multiple tables)
        MangaAuthor.self,
        MangaTag.self,
        MangaCollection.self,
        OriginScanlator.self,
        
        // MARK: - Extensions
        /// FTS
        MangaFTS.self,
    ]
    
    private(set) var writer: DatabaseWriter
    
    var reader: DatabaseReader {
        writer
    }
    
    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        
        try migrator.migrate(writer)
    }
}

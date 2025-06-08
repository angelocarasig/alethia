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
    public let version: Version = Version(1, 0, 4)
    
    public let models: [DatabaseMigratable.Type] = [
        // MARK: - Source Infrastructure
        Host.self,
        Source.self,
        SourceRoute.self,
        
        // MARK: - Core Entities
        Manga.self,
        Origin.self,
        Chapter.self,
        
        // MARK: - Manga Relationships (One-to-Many)
        Title.self,
        Cover.self,
        
        // MARK: - Global Entities (Many-to-Many)
        Author.self,
        Tag.self,
        Collection.self,
        Scanlator.self,
        
        // MARK: - Join Tables
        MangaAuthor.self,
        MangaTag.self,
        MangaCollection.self,
        OriginScanlator.self,
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

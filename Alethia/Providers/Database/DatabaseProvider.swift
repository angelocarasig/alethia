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
    public let version: Version = Version(1, 0, 0)
    
    public let models: [DatabaseMigratable.Type] = [
        // MARK: Fetching
        Host.self, Source.self, SourceRoute.self,
        
        // MARK: Main Metadata
        Manga.self, Origin.self,
        
        // MARK: One-to-Many
        Title.self, Cover.self,
        Scanlator.self, Chapter.self,
        
        // MARK: Many-to-Many
        Author.self, MangaAuthor.self,
        Tag.self, MangaTag.self,
        
        Collection.self, MangaCollection.self,
    ]
    
    let writer: DatabaseWriter
    
    var reader: DatabaseReader {
        writer
    }
    
    init(_ writer: DatabaseWriter) throws {
        self.writer = writer
        
        try migrator.migrate(writer)
        
        #if DEBUG
        // try self.seed(writer)
        #endif
    }
}

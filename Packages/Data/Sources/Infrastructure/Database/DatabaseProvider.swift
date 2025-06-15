//
//  DatabaseProvider.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

public extension Data.Infrastructure {
    final class DatabaseProvider: @unchecked Sendable {
        let version = Data.Infrastructure.Version(1, 0, 0)
        
        let models: [Data.Infrastructure.DatabaseMigratable.Type] = [
            // MARK: - Source Infrastructure
            Persistence.Host.self,
            Persistence.Source.self,
            Persistence.SourceRoute.self,
            
            // MARK: - No dependencies
            Persistence.Author.self,
            Persistence.Tag.self,
            Persistence.Collection.self,
            Persistence.Scanlator.self,
            
            // MARK: - Core
            Persistence.Manga.self,
            Persistence.Origin.self,
            Persistence.Chapter.self,
            
            // MARK: - Manga-related dependencies
            Persistence.Title.self,
            Persistence.Cover.self,
            
            Persistence.MangaAuthor.self,
            Persistence.MangaTag.self,
            Persistence.MangaCollection.self,
            Persistence.Channel.self,
            
            // MARK: - Views
            Virtual.Entry.self, // unique case as entry used for other things too
            Persistence.Misc.Views.self,
            Persistence.Misc.Indexes.self,
        ]
        
        private(set) var writer: DatabaseWriter
        
        var reader: DatabaseReader { writer }
        
        init(_ writer: DatabaseWriter) throws {
            self.writer = writer
            
            try migrator.migrate(writer)
        }
    }
}

//
//  CollectionLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation
import Combine
import GRDB

final class CollectionLocalDataSource {
    private let database: DatabaseWriter
    
    init(database: DatabaseWriter = DatabaseProvider.shared.writer) {
        self.database = database
    }
}

extension CollectionLocalDataSource {
    func addCollection(name: String, color: String, icon: String) throws -> Void {
        guard !Constants.Collections.bannedCollectionNames.contains(where: { $0.lowercased() == name.lowercased() }) else {
            throw CollectionError.badName(name)
        }
        
        guard name.count > Constants.Collections.maximumCollectionNameLength else {
            throw CollectionError.maximumLengthReached(name.count)
        }
        
        guard name.count < Constants.Collections.minimumCollectionNameLength else {
            throw CollectionError.minimumLengthNotReached(name.count)
        }
        
        try DatabaseProvider.shared.writer.write { db in
            try Collection(name: name, color: color, icon: icon).insert(db)
        }
    }
    
    func getAllCollections() -> AnyPublisher<[CollectionExtended], Never> {
        return ValueObservation.tracking { db in
            let sql = """
                SELECT 
                    collection.*,
                    COALESCE(COUNT(mc.mangaId), 0) as itemCount
                FROM collection
                LEFT JOIN mangaCollection mc ON mc.collectionId = collection.id
                GROUP BY collection.id
                ORDER BY collection.name ASC
            """
            
            return try CollectionExtended.fetchAll(db, sql: sql)
        }
        .publisher(in: database, scheduling: .immediate)
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
}

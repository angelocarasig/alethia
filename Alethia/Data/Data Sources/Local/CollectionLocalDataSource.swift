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
        
        guard name.count <= Constants.Collections.maximumCollectionNameLength else {
            throw CollectionError.maximumLengthReached(name.count)
        }
        
        guard name.count >= Constants.Collections.minimumCollectionNameLength else {
            throw CollectionError.minimumLengthNotReached(name.count)
        }
        
        try DatabaseProvider.shared.writer.write { db in
            // Get the highest ordering value
            let ordering: Int = try Collection
                .select(max(Collection.Columns.ordering))
                .asRequest(of: Int.self)
                .fetchOne(db) ?? 0
            
            // New collection gets the next ordering value
            try Collection(
                name: name,
                color: color,
                icon: icon,
                ordering: ordering + 1
            ).insert(db)
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
                ORDER BY collection.ordering ASC
            """
            
            return try CollectionExtended.fetchAll(db, sql: sql)
        }
        .publisher(in: database, scheduling: .immediate)
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
    
    func updateCollection(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws -> Void {
        // sanity checks
        guard !Constants.Collections.bannedCollectionNames.contains(where: { $0.lowercased() == newName.lowercased() }) else {
            throw CollectionError.badName(newName)
        }
        
        guard newName.count <= Constants.Collections.maximumCollectionNameLength else {
            throw CollectionError.maximumLengthReached(newName.count)
        }
        
        guard newName.count >= Constants.Collections.minimumCollectionNameLength else {
            throw CollectionError.minimumLengthNotReached(newName.count)
        }
        
        try DatabaseProvider.shared.writer.write { db in
            guard var collection = try Collection.fetchOne(db, id: collectionId) else {
                throw CollectionError.notFound(collectionId)
            }
            
            collection.name = newName
            collection.icon = newIcon
            collection.color = newColor
            
            try collection.update(db)
        }
    }
    
    func deleteCollection(collectionId: Int64) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            guard let collectionToDelete = try Collection.fetchOne(db, id: collectionId) else {
                throw CollectionError.notFound(collectionId)
            }
            
            let deletedOrdering = collectionToDelete.ordering
            
            // Delete the collection
            try collectionToDelete.delete(db)
            
            // Reorder all collections with higher ordering values
            try db.execute(
                sql: """
                    UPDATE collection 
                    SET ordering = ordering - 1 
                    WHERE ordering > ?
                """,
                arguments: [deletedOrdering]
            )
        }
    }
    
    func updateCollectionOrder(collections: [Int64: Int]) throws {
        try database.write { db in
            // convert map to array of tuples sorted by the new ordering value
            let newOrder = collections
                .map { (collectionId: $0.key, ordering: $0.value) }
                .sorted { $0.ordering < $1.ordering }
            
            // validate that ordering values are sequential starting from 0
            let expectedOrderings = Array(0..<newOrder.count)
            let actualOrderings = newOrder.map(\.ordering)
            
            guard actualOrderings == expectedOrderings else {
                throw ApplicationError.internalError
            }
            
            // verify all collections exist
            let collectionIds = newOrder.map(\.collectionId)
            let existingCollections = try Collection
                .filter(collectionIds.contains(Collection.Columns.id))
                .fetchAll(db)
            
            guard existingCollections.count == newOrder.count else {
                throw CollectionError.notFound(nil)
            }
            
            // temporary negative ordering to avoid conflicts
            let baseOffset = -65535
            for (index, (collectionId, _)) in newOrder.enumerated() {
                let tempOrdering = baseOffset - index
                try Collection
                    .filter(Collection.Columns.id == collectionId)
                    .updateAll(db, Collection.Columns.ordering.set(to: tempOrdering))
            }
            
            // update to final ordering values (keeping 0-based)
            for (collectionId, newOrdering) in newOrder {
                try Collection
                    .filter(Collection.Columns.id == collectionId)
                    .updateAll(db, Collection.Columns.ordering.set(to: newOrdering))
            }
        }
    }
}

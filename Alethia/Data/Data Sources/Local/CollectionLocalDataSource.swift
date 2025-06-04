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
        try DatabaseProvider.shared.writer.write { db in
            guard name.lowercased() != "default" else {
                throw CollectionError.badName("default")
            }
            
            try Collection(name: name, color: color, icon: icon).insert(db)
        }
    }
    
    func getAllCollections() -> AnyPublisher<[Collection], Never> {
        return ValueObservation.tracking { db in
            return try Collection.fetchAll(db)
        }
        .publisher(in: database, scheduling: .immediate)
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
}

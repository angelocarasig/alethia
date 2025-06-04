//
//  CollectionRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation
import Combine

final class CollectionRepositoryImpl {
    private let local: CollectionLocalDataSource
    
    init(local: CollectionLocalDataSource) {
        self.local = local
    }
}

extension CollectionRepositoryImpl: CollectionRepository {
    func getCollections(mangaId: Int64) -> AnyPublisher<[Collection], any Error> {
        fatalError()
    }
    
    func getAllCollections() -> AnyPublisher<[CollectionExtended], Never> {
        return local.getAllCollections()
    }
    
    func addCollection(name: String, color: String, icon: String) throws {
        try local.addCollection(name: name, color: color, icon: icon)
    }
}

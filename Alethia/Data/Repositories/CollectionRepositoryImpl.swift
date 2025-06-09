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
    
    func updateCollection(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws {
        try local.updateCollection(collectionId: collectionId, newName: newName, newIcon: newIcon, newColor: newColor)
    }
    
    func deleteCollection(collectionId: Int64) throws {
        try local.deleteCollection(collectionId: collectionId)
    }
    
    func updateCollectionOrder(collections: [Int64 : Int]) throws {
        try local.updateCollectionOrder(collections: collections)
    }
}

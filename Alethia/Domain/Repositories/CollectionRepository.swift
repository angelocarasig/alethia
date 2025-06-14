//
//  CollectionRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation
import Combine

protocol CollectionRepository {
    func getCollections(mangaId: Int64) -> AnyPublisher<[Collection], Error>
    
    func getAllCollections() -> AnyPublisher<[CollectionExtended], Never>
    
    func addCollection(name: String, color: String, icon: String) throws -> Void
    
    func updateCollection(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws -> Void
    
    func deleteCollection(collectionId: Int64) throws -> Void
    
    // where each ID maps to their new ordering value
    func updateCollectionOrder(collections: [Int64: Int]) throws -> Void
}

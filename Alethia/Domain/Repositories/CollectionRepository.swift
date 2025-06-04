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
}

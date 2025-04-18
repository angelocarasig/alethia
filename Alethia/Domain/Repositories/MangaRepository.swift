//
//  MangaRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

protocol MangaRepository {
    // MARK: Create
    
    // MARK: Read
    
    func getMangaDetail(entry: Entry) -> AnyPublisher<Detail, Error>
    
    // MARK: Update
    
    // MARK: Delete
}

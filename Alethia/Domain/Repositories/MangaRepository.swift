//
//  MangaRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

protocol MangaRepository {
    // Gets library based on search/sort/filters
    func getLibrary(filters: LibraryFilters) -> AnyPublisher<[Entry], Error>
    
    // Returns array for view to handle when multiple matches are found
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Error>
    
    func toggleMangaInLibrary(mangaId: Int64, newValue: Bool) throws -> Void
}

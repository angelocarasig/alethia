//
//  MangaRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

protocol MangaRepository {
    func getLibrary(filters: LibraryFilters) -> AnyPublisher<[Entry], Error>
    
    // Returns array for view to handle when multiple matches are found
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Error>
    
    func addMangaToLibrary(mangaId: Int64, collections: [Int64]) throws -> Void
    
    func removeMangaFromLibrary(mangaId: Int64) throws -> Void
    
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws -> Void
    
    func addMangaOrigin(entry: Entry, mangaId: Int64) async throws -> Void
    
    func updateMangaCover(mangaId: Int64, coverId: Int64) throws -> Void
    
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries
    
    func resolveMangaOrientation(detail: Detail) -> Orientation
}

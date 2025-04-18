//
//  MangaRemoteDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

final class MangaRemoteDataSource {
    private let networkService: NetworkService
    
    init() {
        self.networkService = NetworkService()
    }
    
    func fetchMangaDetail(entry: Entry) async throws -> DetailDTO {
        guard let fetchUrl = entry.fetchUrl,
              let url = URL(string: fetchUrl)
        else { throw NetworkError.missingURL }
        
        return try await networkService.request(url: url)
    }
}

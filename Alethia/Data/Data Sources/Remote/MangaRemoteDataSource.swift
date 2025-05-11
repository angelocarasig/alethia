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
        else {
            let reason = "Entry titled: \(entry.title) does not have a valid fetch URL: '\(entry.fetchUrl ?? "")'"
            throw ApplicationError.urlBuildingFailed(reason) }
        
        return try await networkService.request(url: url)
    }
}

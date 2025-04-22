//
//  GetMangaDetailUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

/**
 Fetches manga detail metadata based on the provided entry
 - Parameter entry: entry object of the manga to be retrieving
 - Returns: observer to the detail struct
 */
protocol GetMangaDetailUseCase {
    func execute(entry: Entry) -> AnyPublisher<[Detail], Error>
}

final class GetMangaDetailUseCaseImpl: GetMangaDetailUseCase {
    private var repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(entry: Entry) -> AnyPublisher<[Detail], Error> {
        return repository.getMangaDetail(entry: entry)
    }
}

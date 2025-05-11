//
//  GetMangaDetailUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import Combine

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

//
//  GetMangaDetailsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import Domain

public final class GetMangaDetailsUseCaseImpl: GetMangaDetailsUseCase {
    private let repository: MangaRepository
    
    public init(repository: MangaRepository) {
        self.repository = repository
    }
    
    public func execute(entry: Entry) -> AsyncStream<Result<[Manga], any Error>> {
        return repository.getManga(entry: entry)
    }
}

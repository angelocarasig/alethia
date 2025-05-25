//
//  ResolveMangaOrientation.swift
//  Alethia
//
//  Created by Angelo Carasig on 25/5/2025.
//

import Foundation

protocol ResolveMangaOrientationUseCase {
    func execute(detail: Detail) -> Orientation
}

final class ResolveMangaOrientationImpl: ResolveMangaOrientationUseCase {
    private let repository: MangaRepository
    
    init(repository: MangaRepository) {
        self.repository = repository
    }
    
    func execute(detail: Detail) -> Orientation {
        return repository.resolveMangaOrientation(detail: detail)
    }
}

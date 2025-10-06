//
//  GetMangaDetailsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation

public protocol GetMangaDetailsUseCase: Sendable {
    func execute(entry: Entry) -> AsyncStream<Result<[Manga], Error>>
}

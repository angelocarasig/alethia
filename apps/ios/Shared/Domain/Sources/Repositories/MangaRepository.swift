//
//  MangaRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation

public protocol MangaRepository: Sendable {
    func getManga(entry: Entry) -> AsyncStream<Result<[Manga], Error>>
}

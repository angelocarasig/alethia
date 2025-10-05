//
//  SearchRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public protocol SearchRepository: Sendable {
    /// Perform a search using a search preset to return an array of raw entries
    func searchWithPreset(source: Source, preset: SearchPreset) async throws -> [Entry]
}

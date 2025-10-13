//
//  Classification.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

public enum Classification: String, Codable, Sendable, CaseIterable {
    case Unknown
    case Safe
    case Suggestive
    case Explicit
}

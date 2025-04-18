//
//  Classification.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation

enum Classification: String, Codable, CaseIterable {
    case Unknown
    case Safe
    case Suggestive
    case Explicit
}

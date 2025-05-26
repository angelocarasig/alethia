//
//  ScanlatorError.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

enum ScanlatorError: LocalizedError {
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Scanlator Not found"
        }
    }
}

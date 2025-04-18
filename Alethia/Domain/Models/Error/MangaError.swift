//
//  MangaError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

enum MangaError: LocalizedError {
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Manga was not able to be properly loaded"
        }
    }
}

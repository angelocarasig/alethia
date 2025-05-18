//
//  ChapterError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

enum ChapterError: LocalizedError {
    case notFound
    case noContent
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Chapter not found."
        case .noContent:
            return "Chapter found but returned no pages."
        }
    }
}

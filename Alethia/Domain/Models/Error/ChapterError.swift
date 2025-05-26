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
    case notDownloaded
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Chapter not found."
        case .noContent:
            return """
                Chapter could not find any content. 
                This is likely due to a problem with the source (data might be missing or is a placeholder)
                """
        case .notDownloaded:
            // Somehow entered a downloaded retrieval
            return "Tried to retrieve a chapter that was not downloaded."
        case .fileNotFound:
            return "Could not find the downloaded chapter file."
        }
    }
}

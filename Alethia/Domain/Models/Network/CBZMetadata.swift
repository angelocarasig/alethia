//
//  CBZMetadata.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

struct CBZMetadata {
    // From Chapter
    let chapterNumber: Double
    let chapterTitle: String
    let pageCount: Int
    
    // From Manga
    let seriesTitle: String
    let mangaSummary: String
    let authors: [String]
    let tags: [String]
    
    // From Scanlator
    let scanlatorName: String
}

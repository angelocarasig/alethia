//
//  Page.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import Foundation

struct Page: Identifiable, Equatable, Hashable {
    var id: String { "\(chapterNumber)-\(pageNumber)"}
    
    let url: String
    let chapterIndex: Int
    let chapterNumber: Double
    let pageNumber: Int
    
    let isFirstPage: Bool
    let isLastPage:  Bool
    
    func getUnderlyingChapter(chapters: [ChapterExtended]) -> ChapterExtended {
        return chapters[chapterIndex]
    }
}

//
//  ReaderPanel.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import Foundation

enum ReaderPanel {
    case page(ReaderPage)
    case transition(ReaderTransition)
    
    func isPanelPage() -> Bool {
        if case .page = self {
            return true
        }
        return false
    }
    
    func isPanelTransition() -> Bool {
        if case .transition = self {
            return true
        }
        return false
    }
}

struct ReaderTransition {
    let from: ChapterExtended
    let to: ChapterExtended?
    
    let pageCount: Int
}

struct ReaderPage: Identifiable {
    var id: String {
        underlyingChapter.chapter.slug
    }
    
    let underlyingChapter: ChapterExtended
    let pageNumber: Int
    let pageCount: Int
    
    let isFirstPage: Bool
    let isLastPage: Bool
    
    var url: String
    var referer: String {
        underlyingChapter.origin.referer
    }
}

//
//  Page.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

struct Page: Identifiable, Equatable, Hashable {
    static func == (lhs: Page, rhs: Page) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: Slug {
        chapter.slug
    }
    
    let chapter: Chapter
    let pageNumber: Int
    let totalPages: Int
    let contentUrl: String
    let contentReferer: String
    
    let isFirstPage: Bool
    let isLastPage: Bool
    
    init(
        chapter: Chapter,
        pageNumber: Int,
        totalPages: Int,
        contentUrl: String,
        contentReferer: String,
        isFirstPage: Bool,
        isLastPage: Bool
    ) {
        self.chapter = chapter
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.contentUrl = contentUrl
        self.contentReferer = contentReferer
        self.isFirstPage = isFirstPage
        self.isLastPage = isLastPage
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

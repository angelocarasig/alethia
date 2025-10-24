//
//  PageMapper.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// maps global page indices to chapter and page-within-chapter
final class PageMapper {
    private var mapping: [Int: (chapterId: ChapterID, page: Int)] = [:]
    private var chapterPageCounts: [ChapterID: Int] = [:]
    
    func updateMapping(chapters: [(id: ChapterID, pages: [String])], orderedBy chapterIds: [ChapterID]) {
        mapping.removeAll()
        chapterPageCounts.removeAll()
        
        var globalIndex = 0
        
        for chapterId in chapterIds {
            guard let chapterData = chapters.first(where: { $0.id == chapterId }) else { continue }
            let pages = chapterData.pages
            
            chapterPageCounts[chapterId] = pages.count
            
            for pageIndex in 0..<pages.count {
                mapping[globalIndex] = (chapterId: chapterId, page: pageIndex)
                globalIndex += 1
            }
        }
    }
    
    func getChapterAndPage(for globalIndex: Int) -> (chapterId: ChapterID, page: Int)? {
        return mapping[globalIndex]
    }
    
    func getGlobalIndex(for chapterId: ChapterID, page: Int) -> Int? {
        return mapping.first(where: { $0.value.chapterId == chapterId && $0.value.page == page })?.key
    }
    
    func getCurrentChapterPageCount(for chapterId: ChapterID) -> Int {
        return chapterPageCounts[chapterId] ?? 0
    }
}

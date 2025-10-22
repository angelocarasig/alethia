//
//  Reader+Callbacks.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import UIKit

// MARK: - Page Tracking & Callbacks

extension Reader {
    
    func updateVisiblePages() {
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        let newVisiblePages = Set(visibleIndexPaths.map { $0.item })
        visiblePages = newVisiblePages
        
        if let highestGlobalIndex = visiblePages.max(),
           let result = pageMapper.getChapterAndPage(for: highestGlobalIndex) {
            
            // check if chapter changed
            if result.chapterId != currentChapterId {
                currentChapterId = result.chapterId
                
                if let chapter = currentChapter {
                    onChapterChange?(chapter)
                }
            }
            
            // check if page changed
            if result.page != currentPage {
                currentPage = result.page
                
                if let chapter = currentChapter {
                    onPageChange?(result.page, chapter)
                }
            }
        }
    }
}

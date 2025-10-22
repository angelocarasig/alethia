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
        
        // determine current page based on reading mode
        let currentIndex: Int?
        
        switch configuration.readingMode {
        case .infinite:
            // use highest visible index (furthest down the page)
            currentIndex = visiblePages.max()
            
        case .vertical, .leftToRight, .rightToLeft:
            // use offset calculation for paged modes
            currentIndex = calculatePagedIndex()
        }
        
        guard let globalIndex = currentIndex,
              let result = pageMapper.getChapterAndPage(for: globalIndex) else {
            return
        }
        
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
    
    private func calculatePagedIndex() -> Int? {
        guard !cachedImageURLs.isEmpty else { return nil }
        
        let pageSize: CGFloat
        let offset: CGFloat
        
        switch configuration.readingMode {
        case .vertical:
            pageSize = collectionView.bounds.height
            offset = collectionView.contentOffset.y
            
        case .leftToRight, .rightToLeft:
            pageSize = collectionView.bounds.width
            offset = collectionView.contentOffset.x
            
        case .infinite:
            return nil
        }
        
        // guard against zero page size (layout not ready)
        guard pageSize > 0 else { return 0 }
        
        // calculate page index from offset
        let calculatedIndex = Int(round(offset / pageSize))
        
        // clamp to valid range
        let maxIndex = max(0, cachedImageURLs.count - 1)
        return min(max(0, calculatedIndex), maxIndex)
    }
}

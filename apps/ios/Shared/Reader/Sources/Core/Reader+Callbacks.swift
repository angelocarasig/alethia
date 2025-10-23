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
        
        print("Current position: chapter=\(String(describing: result.chapterId)), page=\(result.page)")
        
        // check if chapter changed
        if result.chapterId != currentChapterId {
            handleChapterChange(to: result.chapterId)
        }
        
        // check if page changed
        if result.page != currentPage {
            handlePageChange(to: result.page)
        }
    }
    
    private func handleChapterChange(to newChapterId: ChapterID) {
        print("Chapter changed to: \(String(describing: newChapterId))")
        
        currentChapterId = newChapterId
        
        if let chapter = currentChapter {
            onChapterChange?(chapter)
            
            // mark chapter as read/viewed if needed
            Task {
                await markChapterRead(chapter)
            }
        }
    }
    
    private func handlePageChange(to newPage: Int) {
        currentPage = newPage
        
        if let chapter = currentChapter {
            onPageChange?(newPage, chapter)
            
            // save reading progress
            Task {
                await saveReadingProgress(chapter: chapter, page: newPage)
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
    
    // MARK: - Progress Tracking
    
    private func markChapterRead(_ chapter: AnyReadableChapter) async {
        print("Marking chapter as read: \(String(describing: chapter.id))")
        // TODO: 
    }
    
    private func saveReadingProgress(chapter: AnyReadableChapter, page: Int) async {
        print("Saving progress: chapter=\(String(describing: chapter.id)), page=\(page)")
        // TODO: 
    }
}

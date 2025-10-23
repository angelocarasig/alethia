//
//  Reader+Callbacks.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import UIKit

// MARK: - Page Tracking & Callbacks

extension Reader {
    
    func updateVisiblePages(reason: ChangeReason = .userScroll) {
        // don't update during zooming or state transitions
        guard !isAnyPageZoomed,
              !stateMachine.isLoading || reason == .preloadInsert else {
            return
        }
        
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems
        
        let newVisiblePages = Set(visibleIndexPaths.map { $0.item })
        visiblePages = newVisiblePages
        
        // determine current page based on reading mode
        let currentIndex: Int?
        
        switch configuration.readingMode {
        case .infinite:
            // use center-anchored computation for stability
            currentIndex = calculateCenterAnchoredIndex()
            
        case .vertical:
            // use page-based calculation
            currentIndex = calculatePagedIndex()
            
        case .leftToRight, .rightToLeft:
            // use page-based calculation with RTL awareness
            currentIndex = calculateHorizontalPagedIndex()
        }
        
        guard let globalIndex = currentIndex,
              let result = pageMapper.getChapterAndPage(for: globalIndex) else {
            return
        }
        
        print("[Callbacks] Current position: chapter=\(String(describing: result.chapterId)), page=\(result.page), reason=\(reason)")
        
        // prepare callback context
        let context = CallbackManager.CallbackContext(
            chapterId: result.chapterId,
            page: result.page,
            totalPages: pageMapper.getCurrentChapterPageCount(for: result.chapterId),
            reason: reason
        )
        
        // check if chapter changed
        if result.chapterId != currentChapterId {
            handleChapterChange(to: result.chapterId, context: context)
        }
        
        // check if page changed
        if result.page != currentPage {
            handlePageChange(to: result.page, context: context)
        }
    }
    
    private func handleChapterChange(to newChapterId: ChapterID, context: CallbackManager.CallbackContext) {
        print("[Callbacks] Chapter changed to: \(String(describing: newChapterId))")
        
        currentChapterId = newChapterId
        
        // emit chapter change through callback manager
        callbackManager.emitChapterChange(context)
        
        // mark chapter as read/viewed if needed
        if let chapter = currentChapter {
            Task {
                await markChapterRead(chapter)
            }
        }
    }
    
    private func handlePageChange(to newPage: Int, context: CallbackManager.CallbackContext) {
        currentPage = newPage
        
        // emit page change through callback manager
        callbackManager.emitPageChange(context)
        
        // save reading progress
        if let chapter = currentChapter {
            Task {
                await saveReadingProgress(chapter: chapter, page: newPage)
            }
        }
    }
    
    // MARK: - Page Index Calculations
    
    private func calculateCenterAnchoredIndex() -> Int? {
        guard !cachedImageURLs.isEmpty else { return nil }
        
        // find the item at the center of the visible area
        let centerY = collectionView.contentOffset.y + (collectionView.bounds.height / 2)
        let centerPoint = CGPoint(x: collectionView.bounds.midX, y: centerY)
        
        if let indexPath = collectionView.indexPathForItem(at: centerPoint) {
            return indexPath.item
        }
        
        // fallback to highest visible index
        return visiblePages.max()
    }
    
    private func calculatePagedIndex() -> Int? {
        guard !cachedImageURLs.isEmpty else { return nil }
        
        let pageSize = collectionView.bounds.height
        let offset = collectionView.contentOffset.y
        
        // guard against zero page size (layout not ready)
        guard pageSize > 0 else { return 0 }
        
        // calculate page index from offset with center-based rounding
        let centerOffset = offset + (pageSize / 2)
        let calculatedIndex = Int(floor(centerOffset / pageSize))
        
        // clamp to valid range
        let maxIndex = max(0, cachedImageURLs.count - 1)
        return min(max(0, calculatedIndex), maxIndex)
    }
    
    private func calculateHorizontalPagedIndex() -> Int? {
        guard !cachedImageURLs.isEmpty else { return nil }
        
        let pageSize = collectionView.bounds.width
        let offset = collectionView.contentOffset.x
        
        // guard against zero page size (layout not ready)
        guard pageSize > 0 else { return 0 }
        
        // handle RTL mode
        let effectiveOffset: CGFloat
        if configuration.readingMode == .rightToLeft {
            // in RTL, content offset increases as we go "back"
            let maxOffset = max(0, collectionView.contentSize.width - collectionView.bounds.width)
            effectiveOffset = maxOffset - offset
        } else {
            effectiveOffset = offset
        }
        
        // calculate page index with center-based rounding
        let centerOffset = effectiveOffset + (pageSize / 2)
        let calculatedIndex = Int(floor(centerOffset / pageSize))
        
        // clamp to valid range
        let maxIndex = max(0, cachedImageURLs.count - 1)
        return min(max(0, calculatedIndex), maxIndex)
    }
    
    // MARK: - Progress Tracking
    
    private func markChapterRead(_ chapter: AnyReadableChapter) async {
        print("[Progress] Marking chapter as read: \(String(describing: chapter.id))")
        // TODO: implement actual persistence
    }
    
    private func saveReadingProgress(chapter: AnyReadableChapter, page: Int) async {
        print("[Progress] Saving progress: chapter=\(String(describing: chapter.id)), page=\(page)")
        // TODO: implement actual persistence
    }
}

//
//  VerticalReader+Layout.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/5/2025.
//

extension VerticalReader: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let screenHeight = collectionView.bounds.height
        
        guard indexPath.item < pages.count else {
            return CGSize(width: width, height: width * 1.5) // Default fallback
        }
        
        let page = pages[indexPath.item]
        
        switch orientation {
        case .Infinite:
            // Use original proportional sizing for Infinite mode
            let height = getEstimatedHeight(for: page.url)
            return CGSize(width: width, height: height)
            
        case .Vertical:
            // For Vertical (pagination) mode, use actual screen height
            // For true pagination, the cell size should be exactly screen height
            // to ensure proper centering and pagination behavior
            
            // For any image, keep the cell height constant at screen height
            // This ensures exact page-based navigation
            return CGSize(width: width, height: screenHeight)
            
        case .LeftToRight, .RightToLeft:
            // Will be implemented later - using screen width for horizontal pagination
            return CGSize(width: width, height: screenHeight)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Notify as soon as the user starts dragging
        delegate?.didStartScrolling()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Find the most visible cell
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        // Also get the current visible index paths to track chapter transitions
        let visibleIndexPaths = collectionView.indexPathsForVisibleItems.sorted { $0.item < $1.item }
        
        // Get the first visible index path
        let firstVisibleIP = visibleIndexPaths.first
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint),
           indexPath.item < pages.count {
            let page = pages[indexPath.item]
            delegate?.didScrollToPage(page)
            
            // Check if the chapter has changed
            if let lastChapter = lastVisitedChapter, lastChapter.id != page.chapter.id {
                delegate?.didChangeChapter(from: lastChapter, to: page.chapter)
                lastVisitedChapter = page.chapter
            }
            
            // Update current chapter index based on visible page
            if let chapterIndex = chapters.firstIndex(where: { $0.id == page.chapter.id }) {
                currentChapterIndex = chapterIndex
            }
            
            // Check if we need to load more chapters
            if page.isLastPage && indexPath.item == pages.count - 1 {
                loadNextChapter()
                delegate?.didFinishChapter(page.chapter)
            } else if page.isFirstPage && indexPath.item == 0 {
                loadPreviousChapter()
            }
            
            // Preload chapters when approaching edges
            checkForNextChapterPreload(scrollView)
            checkForPreviousChapterPreload(scrollView)
            
            // Debug info
            print("Current chapter: \(page.chapter.number), Index: \(currentChapterIndex), First visible: \(indexPath.item)")
        }
    }
    
    private func checkForNextChapterPreload(_ scrollView: UIScrollView) {
        // Guard against edge cases
        guard 
            !chapters.isEmpty,
            currentChapterIndex < chapters.count - 1, // Not on the last chapter
            scrollView.contentSize.height > 0, // Content is loaded
            !isLoadingChapter // Not already loading a chapter
        else { 
            return 
        }
        
        let scrollViewHeight = scrollView.frame.size.height
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        
        // Calculate distance from bottom
        let distanceFromBottom = scrollContentSizeHeight - scrollOffset - scrollViewHeight
        
        // Calculate 20% threshold of content height
        let threshold = scrollContentSizeHeight * 0.2
        
        // If we're within 20% of the bottom, preload next chapter
        if distanceFromBottom < threshold {
            // Check if the next chapter is the one after the current one
            let nextChapterIndex = currentChapterIndex + 1
            
            // Ensure index is valid
            guard nextChapterIndex < chapters.count else { return }
            
            let nextChapter = chapters[nextChapterIndex]
            
            // Skip if no id or already preloaded
            guard 
                let nextChapterId = nextChapter.id,
                !preloadedChapterIds.contains(nextChapterId)
            else {
                return
            }
            
            print("Preloading next chapter \(nextChapter.number) as user is within 20% of bottom")
            
            // Use a separate thread for preloading to avoid UI stuttering
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadNextChapter()
                }
            }
        }
    }
    
    private func checkForPreviousChapterPreload(_ scrollView: UIScrollView) {
        // Guard against edge cases
        guard 
            !chapters.isEmpty,
            currentChapterIndex > 0, // Not on the first chapter
            scrollView.contentSize.height > 0, // Content is loaded
            !isLoadingChapter // Not already loading a chapter
        else { 
            return
        }
        
        let scrollContentSizeHeight = scrollView.contentSize.height
        let scrollOffset = scrollView.contentOffset.y
        
        // Calculate distance from top
        let distanceFromTop = scrollOffset
        
        // Calculate 20% threshold of content height
        let threshold = scrollContentSizeHeight * 0.2
        
        // If we're within 20% of the top, preload previous chapter
        if distanceFromTop < threshold {
            print("Within 20% of top - checking for previous chapter")
            
            // Check if the previous chapter is the one before the current one
            let previousChapterIndex = currentChapterIndex - 1
            
            // Ensure index is valid
            guard previousChapterIndex >= 0 else { 
                print("No previous chapter available")
                return 
            }
            
            let previousChapter = chapters[previousChapterIndex]
            print("Previous chapter would be: \(previousChapter.number)")
            
            // Skip if no id or already preloaded
            guard 
                let previousChapterId = previousChapter.id,
                !preloadedChapterIds.contains(previousChapterId)
            else {
                print("Previous chapter \(previousChapter.number) already preloaded or has no ID")
                return
            }
            
            print("Preloading previous chapter \(previousChapter.number) as user is within 20% of top")
            
            // Use a separate thread for preloading to avoid UI stuttering
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.loadPreviousChapter()
                }
            }
        }
    }
}

class NoSpacingFlowLayout: UICollectionViewFlowLayout {
    // Reference to know which mode we're using
    var orientation: Orientation = .Infinite
    
    override func prepare() {
        super.prepare()
        
        switch orientation {
        case .Vertical:
            // For true pagination mode, we don't need spaces between cells
            // since each cell is already full-screen height and we use our
            // custom targetContentOffset implementation for paging
            minimumLineSpacing = 0
            
            // No side insets to maximize content
            sectionInset = .zero
            
        case .LeftToRight, .RightToLeft:
            // Will be implemented later
            minimumLineSpacing = 0
            sectionInset = .zero
            
        case .Infinite:
            // For Infinite scrolling, keep items tight together
            minimumLineSpacing = 0
            sectionInset = .zero
        }
        
        minimumInteritemSpacing = 0
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)
        
        // Ensure cell width matches collection view width
        layoutAttributes?.forEach { attribute in
            attribute.frame.origin.x = 0
            attribute.frame.size.width = collectionView?.bounds.width ?? attribute.frame.size.width
        }
        
        return layoutAttributes
    }
    
    // For Vertical paging mode, implement custom paging behavior
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        switch orientation {
        case .Vertical:
            // Continue with Vertical pagination logic
            break
        case .LeftToRight, .RightToLeft:
            // Will be implemented later
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        case .Infinite:
            // No custom behavior for Infinite scrolling
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        // Get visible cells to determine exact item positions
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        guard let attributes = layoutAttributesForElements(in: visibleRect), !attributes.isEmpty else {
            return proposedContentOffset
        }
        
        // Get the screen height (page height)
        let screenHeight = collectionView.bounds.height
        
        // Get the closest indexPath based on current position
        var currentIndex = 0
        var minDistance = CGFloat.greatestFiniteMagnitude
        for (index, attribute) in attributes.enumerated() {
            let distance = abs(attribute.center.y - (collectionView.contentOffset.y + screenHeight/2))
            if distance < minDistance {
                minDistance = distance
                currentIndex = index
            }
        }
        
        // Calculate target index based on swipe direction
        let velocityThreshold: CGFloat = 0.3
        let targetIndex: Int
        
        if velocity.y > velocityThreshold {
            // Fast swipe down - move to next item
            targetIndex = min(currentIndex + 1, attributes.count - 1)
        } else if velocity.y < -velocityThreshold {
            // Fast swipe up - move to previous item
            targetIndex = max(currentIndex - 1, 0)
        } else {
            // Slow scroll - snap to closest
            targetIndex = currentIndex
        }
        
        // Get the target item's attributes
        let targetAttribute = attributes[targetIndex]
        
        // Compute the exact position to target - align top of cell with top of screen
        return CGPoint(x: 0, y: targetAttribute.frame.minY)
    }
}
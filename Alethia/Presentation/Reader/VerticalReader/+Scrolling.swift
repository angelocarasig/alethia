//
//  +Scrolling.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit

extension VerticalReaderController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_: UIScrollView) {
        onScrollStop()
    }
    
    func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        onScrollStop()
    }
    
    func scrollViewDidEndScrollingAnimation(_: UIScrollView) {
        onScrollStop()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onUserDidScroll(to: scrollView.contentOffset.y)
    }
}

extension VerticalReaderController {
    func updateChapterScrollRange() {
        currentChapterRange = getScrollRange()
    }
    
    func scrollPosition(for pct: Double) -> CGFloat {
        let total = currentChapterRange.max - currentChapterRange.min
        var amount = total * pct
        amount += currentChapterRange.min
        return amount
    }
    
    func setScrollPercentage() {
        let contentOffset = offset
        let total = currentChapterRange.max - currentChapterRange.min
        
        // Guard against invalid values
        guard total > 0 else { return }
        
        var current = contentOffset - currentChapterRange.min
        current = max(0, current)
        current = min(current, total) // Ensure we don't go over total
        
        let target = Double(current) / Double(total)
        
        Task { @MainActor [weak self] in
            self?.vm.sliderControls.current = target
        }
    }
    
    func onScrollStop() {
        // Load Previous Chapter if requested
        if didTriggerBackTick {
            Task { [weak self] in
                await self?.loadPreviousChapter()
            }
            didTriggerBackTick = false
        }
        
        let currentPath = pathAtCenterOfScreen
        guard let currentPath else { return }
        
        guard let page = dataSource.itemIdentifier(for: currentPath) else { return }
        didChangePage(page, indexPath: currentPath)
        lastIndexPath = currentPath
        
        // Update scroll percentage for slider
        updateChapterScrollRange()
        setScrollPercentage()
    }
    
    func onUserDidScroll(to position: CGFloat) {
        // If current offset is lower than 0, user wants to see previous chapter
        if position < 0, !didTriggerBackTick {
            didTriggerBackTick = true
            return
        }
        
        // Update Last Scroll Position
        let difference = abs(position - lastKnownScrollPosition)
        guard difference >= scrollPositionUpdateThreshold else { return }
        lastKnownScrollPosition = position
        
        // Only real-time update when the user is not scrubbing & the menu is being shown
        guard !vm.sliderControls.isScrubbing, vm.showControls else { return }
        Task { @MainActor [weak self] in
//            if Preferences.standard.readerHideMenuOnSwipe {
            // TODO: Hide controls
//                self?.vm.showControls = false
//            }
            self?.setScrollPercentage()
        }
    }
}

extension VerticalReaderController {
    func handleSliderPositionChange(_ value: Double) {
        guard vm.sliderControls.isScrubbing else {
            return
        }
        let position = scrollPosition(for: value)
        let point = CGPoint(x: 0,
                            y: position)
        
        defer {
            collectionNode
                .setContentOffset(point, animated: false)
        }
        guard let path = collectionNode.indexPathForItem(at: point),
              case let .page(page) = dataSource.itemIdentifier(for: path)
        else {
            return
        }
        
        vm.readerState.pageNumber = page.pageNumber
    }
    
    func getScrollRange() -> (min: CGFloat, max: CGFloat) {
        let def: (min: CGFloat, max: CGFloat) = (min: .zero, max: .zero)
        var sectionMinOffset: CGFloat = .zero
        var sectionMaxOffset: CGFloat = .zero
        
        // Get current path
        guard let path = pathAtCenterOfScreen else {
            return def
        }
        
        // Get item at current path
        guard let item = dataSource.itemIdentifier(for: path) else {
            return def
        }
        
        // Get all items in the current chapter section
        let section = dataSource.itemIdentifiers(inSection: item.chapter.slug)
        
        // Find first page index (skip transitions)
        let minIndex = section.firstIndex(where: \.isPage)
        
        // Last content index (before the final transition)
        let maxIndex = max(section.endIndex - 2, 0)
        
        // Get collection view reference
        let collectionView = collectionNode.view
        
        // Get min Y position
        if let minIndex {
            let minPath = IndexPath(item: minIndex, section: path.section)
            if let attributes = collectionView.layoutAttributesForItem(at: minPath) {
                let frame = attributes.frame
                sectionMinOffset = frame.minY
            }
        }
        
        // Get max Y position
        let maxPath = IndexPath(item: maxIndex, section: path.section)
        if let attributes = collectionView.layoutAttributesForItem(at: maxPath) {
            let frame = attributes.frame
            sectionMaxOffset = frame.maxY - collectionNode.frame.height
        }
        
        // Make sure min is not greater than max
        if sectionMinOffset > sectionMaxOffset {
            sectionMinOffset = .zero
        }
        
        return (min: sectionMinOffset, max: max(sectionMaxOffset, 0))
    }
}

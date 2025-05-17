//
//  +Events.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

extension VerticalReaderController {
    func didChangePage(_ item: ReaderPanel, indexPath: IndexPath) {
        let chapter = item.chapter
        
        if !vm.isCurrentlyReading(chapter) {
            didChapterChange(to: chapter)
        }
        
        switch item {
        case let .page(page):
            let target = page
            vm.updateViewerState(with: target)
            didReadPage(target, path: indexPath)
        case let .transition(transition):
            vm.updateViewerState(with: transition)
            didCompleteChapter(chapter)
            
            if transition.to == nil {
                print("TODO: On transition to nil show menu")
//                vm.showMenu()
            }
        }
    }
    
    func didCompleteChapter(_ chapter: Chapter) {
        print("TODO: Implement Chapter Completion handler")
    }
    
    func didChapterChange(to chapter: Chapter) {
        // Update Scrub Range
//        currentChapterRange = getScrollRange()
        vm.updateViewerStateChapter(chapter)
    }
    
    func didReadPage(_ page: Page, path: IndexPath) {
        let pixelsSinceLastStop = abs(offset - lastStoppedScrollPosition)
        let pageOffset = calculateCurrentOffset(of: path)
        
        // is last page, has completed 95% of the chapter, mark as completed
        if page.isLastPage, let pageOffset, pageOffset >= 0.95 {
            didCompleteChapter(page.chapter)
            return
        }
        
        // TODO: Update read progress here
    }
    
    private func calculateCurrentOffset(of path: IndexPath) -> Double? {
        guard let frame = frameOfItem(at: path) else { return nil }
        let size = frame.size
        let pageTop = frame.minY
        let currentOffset = offset
        let pageOffset = Double(currentOffset - pageTop) / size.height
        return pageOffset
    }
}

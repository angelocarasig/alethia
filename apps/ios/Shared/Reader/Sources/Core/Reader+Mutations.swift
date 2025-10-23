//
//  Reader+Mutations.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import UIKit
import Kingfisher

// MARK: - Chapter Position

extension Reader {
    enum ChapterPosition {
        case initial
        case previous
        case next
    }
}

// MARK: - Chapter Loading & Mutations

extension Reader {
    
    func loadChapter(_ chapterId: ChapterID, position: ChapterPosition) async {
        print("[Reader] Loading chapter at position: \(String(describing: position))")
        
        let isLoaded = await chapterManager.isChapterLoaded(chapterId)
        guard !isLoaded else {
            print("[Reader] Chapter already loaded")
            
            if position == .initial {
                await MainActor.run {
                    Task {
                        await self.applyInitialChapter()
                    }
                }
            }
            return
        }
        
        do {
            // load chapter data
            let imageURLs = try await chapterManager.loadChapter(chapterId)
            
            print("[Reader] Chapter loaded with \(imageURLs.count) pages")
            
            // notify completion
            await MainActor.run {
                onChapterLoadComplete?(chapterId, imageURLs.count)
            }
            
            // check if we got pages
            guard !imageURLs.isEmpty else {
                print("[Reader] Chapter has no pages")
                
                switch position {
                case .previous:
                    await chapterManager.finishLoadingPrevious()
                case .next:
                    await chapterManager.finishLoadingNext()
                case .initial:
                    break
                }
                return
            }
            
            // apply to collection view
            await MainActor.run {
                Task {
                    switch position {
                    case .initial:
                        await self.applyInitialChapter()
                        
                    case .previous:
                        await self.insertPreviousChapter()
                        
                    case .next:
                        await self.insertNextChapter()
                    }
                }
            }
        } catch {
            print("[Reader] Failed to load chapter: \(error)")
            
            // notify error handler
            await MainActor.run {
                onError?(error)
            }
            
            // reset loading flags
            switch position {
            case .previous:
                await chapterManager.finishLoadingPrevious()
            case .next:
                await chapterManager.finishLoadingNext()
            case .initial:
                break
            }
        }
    }
    
    // MARK: - Chapter Application
    
    private func applyInitialChapter() async {
        print("[Reader] Applying initial chapter")
        
        guard let pending = pendingState else {
            print("[Reader] No pending state")
            return
        }
        
        await updateCachedData()
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        
        // scroll to the requested chapter and page
        if let firstPageIndex = pageMapper.getGlobalIndex(for: pending.chapterId, page: pending.page) {
            print("[Reader] Scrolling to chapter at index \(firstPageIndex)")
            
            let indexPath = IndexPath(item: firstPageIndex, section: 0)
            
            isProgrammaticScroll = true
            
            switch configuration.readingMode {
            case .leftToRight, .rightToLeft:
                collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
            case .infinite, .vertical:
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
            
            isProgrammaticScroll = false
        }
        
        // consume pending state
        pendingState = nil
        isLoaded = true
        
        // trigger initial update
        DispatchQueue.main.async { [weak self] in
            self?.updateVisiblePages()
        }
    }
    
    private func insertPreviousChapter() async {
        print("[Reader] Inserting previous chapter")
        
        let preservedPosition = preserveScrollPosition()
        
        await updateCachedData()
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
        
        // restore position
        restoreScrollPosition(preservedPosition)
        
        await chapterManager.finishLoadingPrevious()
    }
    
    private func insertNextChapter() async {
        print("[Reader] Inserting next chapter")
        
        await updateCachedData()
        
        collectionView.reloadData()
        
        await chapterManager.finishLoadingNext()
    }
    
    // MARK: - Scroll Position Preservation
    
    private struct ScrollPosition {
        let contentOffset: CGPoint
        let contentSize: CGSize
        let chapterId: ChapterID
        let page: Int
    }
    
    private func preserveScrollPosition() -> ScrollPosition {
        // get current chapter and page
        var chapterId = currentChapterId
        var page = currentPage
        
        // try to get more accurate position from visible items
        if let visiblePath = collectionView.indexPathsForVisibleItems.sorted().first,
           let result = pageMapper.getChapterAndPage(for: visiblePath.item) {
            chapterId = result.chapterId
            page = result.page
        }
        
        let position = ScrollPosition(
            contentOffset: collectionView.contentOffset,
            contentSize: collectionView.contentSize,
            chapterId: chapterId,
            page: page
        )
        
        print("[Reader] Preserved position: chapter=\(String(describing: chapterId)), page=\(page)")
        
        return position
    }
    
    private func restoreScrollPosition(_ position: ScrollPosition) {
        // find the new index for the preserved chapter/page
        if let newIndex = pageMapper.getGlobalIndex(for: position.chapterId, page: position.page) {
            print("[Reader] Restoring to index \(newIndex)")
            
            let indexPath = IndexPath(item: newIndex, section: 0)
            
            isProgrammaticScroll = true
            
            switch configuration.readingMode {
            case .leftToRight, .rightToLeft:
                collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
                
            case .infinite, .vertical:
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
            
            isProgrammaticScroll = false
        } else {
            // fallback: adjust by content size difference
            let sizeDiff = collectionView.contentSize.height - position.contentSize.height
            collectionView.contentOffset = CGPoint(
                x: position.contentOffset.x,
                y: position.contentOffset.y + sizeDiff
            )
        }
    }
    
    // MARK: - Preloading
    
    func preloadAdjacentChapters() async {
        // only preload after initial load is complete
        guard isLoaded else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        
        // preload next if exists and not loaded
        if let next = navigation.next {
            let canLoadNext = await chapterManager.canLoadNext(
                current: currentChapterId,
                next: next
            )
            
            if canLoadNext {
                print("[Reader] Preloading next chapter")
                await chapterManager.startLoadingNext()
                await loadChapter(next.id, position: .next)
            }
        }
        
        // preload previous if exists and not loaded
        if let previous = navigation.previous {
            let canLoadPrevious = await chapterManager.canLoadPrevious(
                current: currentChapterId,
                previous: previous
            )
            
            if canLoadPrevious {
                print("[Reader] Preloading previous chapter")
                await chapterManager.startLoadingPrevious()
                await loadChapter(previous.id, position: .previous)
            }
        }
    }
}

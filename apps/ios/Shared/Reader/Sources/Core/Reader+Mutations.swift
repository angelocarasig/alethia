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
        
        // cancel any previous insertion task if we're loading a new chapter
        if position == .initial {
            insertionTask?.cancel()
            insertionTask = nil
        }
        
        // create new task ID for this load operation
        let taskId = UUID()
        insertionTaskId = taskId
        
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
            // premeasure images before loading to reduce reflow
            await premeasureImages(for: chapterId)
            
            // load chapter data
            let imageURLs = try await chapterManager.loadChapter(chapterId)
            
            // check if this task was cancelled
            guard insertionTaskId == taskId else {
                print("[Reader] Load task was superseded, ignoring results")
                return
            }
            
            print("[Reader] Chapter loaded with \(imageURLs.count) pages")
            
            // notify completion
            await MainActor.run {
                self.callbackManager.emitChapterLoadComplete(chapterId: chapterId, pageCount: imageURLs.count)
            }
            
            // check if we got pages
            guard !imageURLs.isEmpty else {
                print("[Reader] Chapter has no pages")
                
                await MainActor.run {
                    self.callbackManager.emitError(ReaderError.emptyPages(chapterId: chapterId))
                    _ = self.stateMachine.transition(to: .error(ReaderError.emptyPages(chapterId: chapterId)))
                }
                
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
            
            // apply to collection view with proper state transitions
            await MainActor.run {
                _ = self.stateMachine.transition(to: .inserting)
                
                self.insertionTask = Task {
                    switch position {
                    case .initial:
                        await self.applyInitialChapter()
                        
                    case .previous:
                        await self.insertPreviousChapterStable()
                        
                    case .next:
                        await self.insertNextChapter()
                    }
                    
                    _ = self.stateMachine.transition(to: .settling)
                    
                    // allow layout to complete
                    await MainActor.run {
                        self.collectionView.layoutIfNeeded()
                    }
                    
                    _ = self.stateMachine.transition(to: .ready)
                }
            }
        } catch {
            print("[Reader] Failed to load chapter: \(error)")
            
            // check if this task was cancelled
            guard insertionTaskId == taskId else {
                print("[Reader] Load task was superseded, ignoring error")
                return
            }
            
            // notify error handler
            await MainActor.run {
                let readerError: ReaderError
                if position == .initial {
                    readerError = .initialChapterFailed(error)
                } else {
                    readerError = .subsequentChapterFailed(chapterId: chapterId, error)
                }
                
                self.callbackManager.emitError(readerError)
                _ = self.stateMachine.transition(to: .error(readerError))
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
    
    // MARK: - Image Premeasurement
    
    private func premeasureImages(for chapterId: ChapterID) async {
        // try to fetch first few pages to get size hints
        do {
            let urls = try await dataSource.fetchPages(for: chapterId)
            let urlsToMeasure = Array(urls.prefix(5)) // measure first 5 pages
            
            await withTaskGroup(of: (String, CGSize?).self) { group in
                for urlString in urlsToMeasure {
                    group.addTask {
                        guard let url = URL(string: urlString) else {
                            return (urlString, nil)
                        }
                        
                        // try to get cached image size
                        if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: url.absoluteString) {
                            return (urlString, image.size)
                        }
                        
                        // try to fetch just headers for size
                        do {
                            let result = try await KingfisherManager.shared.retrieveImage(with: url)
                            return (urlString, result.image.size)
                        } catch {
                            return (urlString, nil)
                        }
                    }
                }
                
                for await (url, size) in group {
                    if let size = size {
                        await MainActor.run {
                            self.imageSizes[url] = size
                        }
                    }
                }
            }
        } catch {
            print("[Reader] Could not premeasure images: \(error)")
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
        
        // suppress callbacks during initial setup
        await callbackManager.suppressDuring(reason: .initialLoad) {
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
        }
        
        // consume pending state
        pendingState = nil
        isLoaded = true
        
        // trigger initial update with proper reason
        DispatchQueue.main.async { [weak self] in
            self?.updateVisiblePages(reason: .initialLoad)
        }
    }
    
    private func insertPreviousChapterStable() async {
        print("[Reader] Inserting previous chapter with stable scroll")
        
        let oldItemCount = cachedImageURLs.count
        
        // track content size and offset before changes (only for infinite mode)
        let contentSizeBefore = collectionView.contentSize
        let offsetBefore = collectionView.contentOffset
        
        // update data model
        await updateCachedData()
        
        let newItemCount = cachedImageURLs.count
        let insertedCount = newItemCount - oldItemCount
        
        guard insertedCount > 0 else {
            await chapterManager.finishLoadingPrevious()
            return
        }
        
        // perform batch update with offset adjustment for infinite mode only
        await withCheckedContinuation { continuation in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            
            collectionView.performBatchUpdates({
                let insertionPaths = (0..<insertedCount).map { IndexPath(item: $0, section: 0) }
                self.collectionView.insertItems(at: insertionPaths)
            }, completion: { _ in
                // only adjust offset for infinite mode to prevent content jump
                if self.configuration.readingMode == .infinite {
                    // calculate how much height was added
                    let heightAdded = self.collectionView.contentSize.height - contentSizeBefore.height
                    
                    if heightAdded > 0 {
                        // add the height difference to the current offset to maintain visual position
                        let newOffset = CGPoint(
                            x: offsetBefore.x,
                            y: offsetBefore.y + heightAdded
                        )
                        self.collectionView.setContentOffset(newOffset, animated: false)
                        print("[Reader] Adjusted offset by \(heightAdded) to maintain position")
                    }
                }
                // for paged modes (vertical, leftToRight, rightToLeft), don't adjust offset
                
                CATransaction.commit()
                continuation.resume()
            })
        }
        
        await chapterManager.finishLoadingPrevious()
        updateVisiblePages(reason: .preloadInsert)
    }
    
    private func insertNextChapter() async {
        print("[Reader] Inserting next chapter")
        
        let oldItemCount = cachedImageURLs.count
        
        // update data model
        await updateCachedData()
        
        let newItemCount = cachedImageURLs.count
        let insertedCount = newItemCount - oldItemCount
        
        guard insertedCount > 0 else {
            await chapterManager.finishLoadingNext()
            return
        }
        
        // perform batch update (no offset adjustment needed for appending)
        await withCheckedContinuation { continuation in
            collectionView.performBatchUpdates({
                let insertionPaths = (oldItemCount..<newItemCount).map { IndexPath(item: $0, section: 0) }
                self.collectionView.insertItems(at: insertionPaths)
            }, completion: { _ in
                continuation.resume()
            })
        }
        
        await chapterManager.finishLoadingNext()
        updateVisiblePages(reason: .preloadInsert)
    }
    
    // MARK: - Preloading
    
    func preloadAdjacentChapters() async {
        // only preload after initial load is complete and we're in ready state
        guard isLoaded, stateMachine.state == .ready else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        
        // preload next if exists and not loaded
        if let next = navigation.next {
            let canLoadNext = await chapterManager.canLoadNext(
                current: currentChapterId,
                next: next
            )
            
            if canLoadNext {
                print("[Reader] Preloading next chapter")
                
                // check state machine allows loading
                if stateMachine.transition(to: .loadingNext) {
                    await chapterManager.startLoadingNext()
                    await loadChapter(next.id, position: .next)
                }
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
                
                // check state machine allows loading
                if stateMachine.transition(to: .loadingPrevious) {
                    await chapterManager.startLoadingPrevious()
                    await loadChapter(previous.id, position: .previous)
                }
            }
        }
    }
}

//
//  Reader+ViewController.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import UIKit
import Kingfisher

// MARK: - UICollectionViewDataSource

extension Reader: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cachedImageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as! ImageCell
        
        guard indexPath.item < cachedImageURLs.count else { return cell }
        
        let urlString = cachedImageURLs[indexPath.item]
        let imageSize = imageSizes[urlString]
        
        print("[Cell] Configuring cell at index \(indexPath.item)")
        
        // configure cell based on reading mode
        switch configuration.readingMode {
        case .infinite:
            cell.configure(
                with: urlString,
                dimension: collectionView.bounds.width,
                dimensionType: .width,
                imageSize: imageSize
            )
        case .vertical:
            cell.configure(
                with: urlString,
                dimension: collectionView.bounds.height,
                dimensionType: .height,
                imageSize: imageSize
            )
        case .leftToRight, .rightToLeft:
            cell.configure(
                with: urlString,
                dimension: 0,
                dimensionType: .aspectFit,
                imageSize: imageSize
            )
        }
        
        // handle zoom state changes
        cell.onZoomStateChanged = { [weak self] isZoomed in
            self?.isAnyPageZoomed = isZoomed
            self?.collectionView.isScrollEnabled = !isZoomed
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension Reader: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension Reader: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("[Prefetch] Prefetching \(indexPaths.count) items")
        
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < cachedImageURLs.count else { return nil }
            let urlString = cachedImageURLs[indexPath.item]
            return URL(string: urlString)
        }
        
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("[Prefetch] Cancelling prefetch for \(indexPaths.count) items")
        
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < cachedImageURLs.count else { return nil }
            let urlString = cachedImageURLs[indexPath.item]
            return URL(string: urlString)
        }
        
        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.stop()
    }
}

// MARK: - UICollectionViewDelegate

extension Reader: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("[Scroll] User started scrolling")
        isProgrammaticScroll = false
        isUserScrolling = true
        callbackManager.emitScrollStateChange(true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            print("[Scroll] User stopped scrolling (no deceleration)")
            isUserScrolling = false
            callbackManager.emitScrollStateChange(false)
            
            // emit final position after scroll settles
            DispatchQueue.main.async { [weak self] in
                self?.updateVisiblePages(reason: .userScroll)
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("[Scroll] Scroll deceleration ended")
        isUserScrolling = false
        callbackManager.emitScrollStateChange(false)
        
        // emit final position after deceleration
        DispatchQueue.main.async { [weak self] in
            self?.updateVisiblePages(reason: .userScroll)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("[Scroll] Programmatic scroll ended")
        isProgrammaticScroll = false
        isUserScrolling = false
        callbackManager.emitScrollStateChange(false)
        
        // emit final position after programmatic scroll
        DispatchQueue.main.async { [weak self] in
            self?.updateVisiblePages(reason: .programmaticJump)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isAnyPageZoomed else { return }
        
        // only update during user scroll, not programmatic
        if isUserScrolling && !isProgrammaticScroll {
            updateVisiblePages(reason: .userScroll)
        }
        
        // don't trigger loading during initial setup, programmatic scroll, or state transitions
        guard isLoaded && !isProgrammaticScroll && stateMachine.canStartLoading else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        
        scrollHandler.handleScroll(
            scrollView: scrollView,
            mode: configuration.readingMode,
            threshold: configuration.loadThreshold,
            onLoadPrevious: { [weak self] in
                guard let self = self else { return }
                
                print("[Scroll] Threshold reached: loading previous")
                
                Task {
                    let canLoad = await self.chapterManager.canLoadPrevious(
                        current: self.currentChapterId,
                        previous: navigation.previous
                    )
                    
                    if canLoad, let previous = navigation.previous {
                        // use state machine to coordinate loading
                        if self.stateMachine.transition(to: .loadingPrevious) {
                            await self.chapterManager.startLoadingPrevious()
                            await self.loadChapter(previous.id, position: .previous)
                        }
                    }
                }
            },
            onLoadNext: { [weak self] in
                guard let self = self else { return }
                
                print("[Scroll] Threshold reached: loading next")
                
                Task {
                    let canLoad = await self.chapterManager.canLoadNext(
                        current: self.currentChapterId,
                        next: navigation.next
                    )
                    
                    if canLoad, let next = navigation.next {
                        // use state machine to coordinate loading
                        if self.stateMachine.transition(to: .loadingNext) {
                            await self.chapterManager.startLoadingNext()
                            await self.loadChapter(next.id, position: .next)
                        }
                    }
                }
            }
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let result = pageMapper.getChapterAndPage(for: indexPath.item) else { return }
        
        let totalPages = pageMapper.getCurrentChapterPageCount(for: result.chapterId)
        let currentPage = result.page
        
        print("[Display] Will display page \(currentPage)/\(totalPages) of chapter")
        
        // only preload when we're in the last 5 pages of a chapter
        let pagesFromEnd = totalPages - currentPage
        if isLoaded && pagesFromEnd <= 5 && stateMachine.canStartLoading {
            Task {
                await preloadAdjacentChapters()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        visiblePages.remove(indexPath.item)
        print("[Display] Cell at index \(indexPath.item) ended display")
    }
}

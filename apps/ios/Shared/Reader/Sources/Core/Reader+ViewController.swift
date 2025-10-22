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
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < cachedImageURLs.count else { return nil }
            let urlString = cachedImageURLs[indexPath.item]
            return URL(string: urlString)
        }
        
        ImagePrefetcher(urls: urls).start()
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard indexPath.item < cachedImageURLs.count else { return nil }
            let urlString = cachedImageURLs[indexPath.item]
            return URL(string: urlString)
        }
        
        ImagePrefetcher(urls: urls).stop()
    }
}

// MARK: - UICollectionViewDelegate

extension Reader: UICollectionViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // reset programmatic scroll flag when user starts dragging
        isProgrammaticScroll = false
        isUserScrolling = true
        onScrollStateChange?(true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isUserScrolling = false
            onScrollStateChange?(false)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        onScrollStateChange?(false)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // programmatic scrolling finished
        isProgrammaticScroll = false
        isUserScrolling = false
        onScrollStateChange?(false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isAnyPageZoomed else { return }
        
        // always update visible pages to keep callbacks in sync
        updateVisiblePages()
        
        // skip chapter loading during programmatic scroll
        guard !isProgrammaticScroll else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        
        scrollHandler.handleScroll(
            scrollView: scrollView,
            mode: configuration.readingMode,
            threshold: configuration.loadThreshold,
            onLoadPrevious: { [weak self] in
                guard let self = self else { return }
                Task {
                    let canLoad = await self.chapterManager.canLoadPrevious(
                        current: self.currentChapterId,
                        previous: navigation.previous
                    )
                    
                    if canLoad, let previous = navigation.previous {
                        await self.chapterManager.startLoadingPrevious()
                        await self.loadChapter(previous.id, position: .previous)
                    }
                }
            },
            onLoadNext: { [weak self] in
                guard let self = self else { return }
                Task {
                    let canLoad = await self.chapterManager.canLoadNext(
                        current: self.currentChapterId,
                        next: navigation.next
                    )
                    
                    if canLoad, let next = navigation.next {
                        await self.chapterManager.startLoadingNext()
                        await self.loadChapter(next.id, position: .next)
                    }
                }
            }
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        visiblePages.remove(indexPath.item)
    }
}

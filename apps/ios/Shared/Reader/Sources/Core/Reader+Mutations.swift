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
        let isLoaded = await chapterManager.isChapterLoaded(chapterId)
        guard !isLoaded else { return }
        
        do {
            let imageURLs = try await chapterManager.fetchChapter(for: chapterId)
            
            await preloadImageSizes(for: imageURLs)
            
            _ = await MainActor.run {
                Task {
                    switch position {
                    case .initial:
                        await chapterManager.setChapter(imageURLs, for: chapterId)
                        await updateCachedData()
                        collectionView.reloadData()
                        
                        // trigger initial state update after first layout
                        DispatchQueue.main.async { [weak self] in
                            self?.updateVisiblePages()
                        }
                        
                    case .previous:
                        await insertPreviousChapter(imageURLs, for: chapterId)
                        
                    case .next:
                        await insertNextChapter(imageURLs, for: chapterId)
                    }
                }
            }
        } catch {
            // notify error handler
            await MainActor.run {
                onError?(error)
            }
            
            // reset loading flags on error
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
    
    private func preloadImageSizes(for urls: [String]) async {
        await withTaskGroup(of: (String, CGSize?).self) { group in
            for urlString in urls {
                group.addTask {
                    guard let url = URL(string: urlString) else {
                        return (urlString, nil)
                    }
                    
                    do {
                        let result = try await KingfisherManager.shared.retrieveImage(with: url)
                        let size = result.image.size
                        return (urlString, size)
                    } catch {
                        return (urlString, nil)
                    }
                }
            }
            
            for await (urlString, size) in group {
                if let size = size {
                    await MainActor.run {
                        imageSizes[urlString] = size
                    }
                }
            }
        }
    }
    
    private func insertPreviousChapter(_ imageURLs: [String], for chapterId: ChapterID) async {
        await MainActor.run {
            if configuration.readingMode == .leftToRight || configuration.readingMode == .rightToLeft {
                let contentOffsetX = collectionView.contentOffset.x
                let contentWidth = collectionView.contentSize.width
                
                Task {
                    await chapterManager.setChapter(imageURLs, for: chapterId)
                    await updateCachedData()
                    
                    await MainActor.run {
                        collectionView.reloadData()
                        collectionView.layoutIfNeeded()
                        
                        let newContentWidth = collectionView.contentSize.width
                        let widthDifference = newContentWidth - contentWidth
                        collectionView.contentOffset.x = contentOffsetX + widthDifference
                        
                        Task {
                            await chapterManager.finishLoadingPrevious()
                        }
                    }
                }
            } else {
                let contentOffsetY = collectionView.contentOffset.y
                let contentHeight = collectionView.contentSize.height
                
                Task {
                    await chapterManager.setChapter(imageURLs, for: chapterId)
                    await updateCachedData()
                    
                    await MainActor.run {
                        collectionView.reloadData()
                        collectionView.layoutIfNeeded()
                        
                        let newContentHeight = collectionView.contentSize.height
                        let heightDifference = newContentHeight - contentHeight
                        collectionView.contentOffset.y = contentOffsetY + heightDifference
                        
                        Task {
                            await chapterManager.finishLoadingPrevious()
                        }
                    }
                }
            }
        }
    }
    
    private func insertNextChapter(_ imageURLs: [String], for chapterId: ChapterID) async {
        _ = await MainActor.run {
            Task {
                await chapterManager.setChapter(imageURLs, for: chapterId)
                await updateCachedData()
                
                await MainActor.run {
                    collectionView.reloadData()
                    
                    Task {
                        await chapterManager.finishLoadingNext()
                    }
                }
            }
        }
    }
}

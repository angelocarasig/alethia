//
//  InsertionStrategy.swift
//  Reader
//
//  Created by Angelo Carasig on 24/10/2025.
//

import UIKit

/// manages anchored insertions for stable content preservation
@MainActor
final class InsertionStrategy {
    
    /// insertion anchor for preserving position
    struct InsertionAnchor {
        let globalIndex: Int
        let chapterId: ChapterID
        let pageInChapter: Int
        let visibleRect: CGRect
        let contentOffset: CGPoint
        let contentSize: CGSize
    }
    
    /// perform anchored batch insertion
    func performAnchoredInsertion(
        collectionView: UICollectionView,
        position: Reader.ChapterPosition,
        anchor: InsertionAnchor?,
        oldItemCount: Int,
        newItemCount: Int,
        pageMapper: PageMapper,
        readingMode: ReadingMode,
        completion: @escaping () -> Void
    ) {
        print("[InsertionStrategy] Performing anchored insertion for \(position)")
        
        // determine insertion ranges
        let insertionRange: Range<Int>
        let deletionRange: Range<Int>?
        
        switch position {
        case .initial:
            // full reload for initial
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            completion()
            return
            
        case .previous:
            // items inserted at beginning
            let insertedCount = newItemCount - oldItemCount
            insertionRange = 0..<insertedCount
            deletionRange = nil
            
        case .next:
            // items inserted at end
            let insertedCount = newItemCount - oldItemCount
            insertionRange = oldItemCount..<newItemCount
            deletionRange = nil
        }
        
        // perform batch update with anchor preservation
        collectionView.performBatchUpdates({
            if let deletionRange = deletionRange {
                let deletionPaths = deletionRange.map { IndexPath(item: $0, section: 0) }
                collectionView.deleteItems(at: deletionPaths)
            }
            
            let insertionPaths = insertionRange.map { IndexPath(item: $0, section: 0) }
            collectionView.insertItems(at: insertionPaths)
        }, completion: { _ in
            // restore anchor position after insertion
            if let anchor = anchor {
                self.restoreAnchor(
                    anchor,
                    in: collectionView,
                    pageMapper: pageMapper,
                    readingMode: readingMode,
                    insertedAtBeginning: position == .previous
                )
            }
            
            completion()
        })
    }
    
    /// capture current anchor for preservation
    func captureAnchor(
        from collectionView: UICollectionView,
        pageMapper: PageMapper,
        readingMode: ReadingMode
    ) -> InsertionAnchor? {
        // find the anchor item based on reading mode
        let anchorIndexPath: IndexPath?
        
        switch readingMode {
        case .infinite:
            // use center of visible area as anchor
            let centerPoint = CGPoint(
                x: collectionView.bounds.midX,
                y: collectionView.contentOffset.y + collectionView.bounds.midY
            )
            anchorIndexPath = collectionView.indexPathForItem(at: centerPoint)
            
        case .vertical:
            // use top visible item as anchor
            let visiblePaths = collectionView.indexPathsForVisibleItems.sorted()
            anchorIndexPath = visiblePaths.first
            
        case .leftToRight, .rightToLeft:
            // use leftmost (or rightmost for RTL) visible item
            let visiblePaths = collectionView.indexPathsForVisibleItems.sorted()
            anchorIndexPath = readingMode == .rightToLeft ? visiblePaths.last : visiblePaths.first
        }
        
        guard let indexPath = anchorIndexPath,
              let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath),
              let chapterAndPage = pageMapper.getChapterAndPage(for: indexPath.item) else {
            return nil
        }
        
        return InsertionAnchor(
            globalIndex: indexPath.item,
            chapterId: chapterAndPage.chapterId,
            pageInChapter: chapterAndPage.page,
            visibleRect: layoutAttributes.frame,
            contentOffset: collectionView.contentOffset,
            contentSize: collectionView.contentSize
        )
    }
    
    private func restoreAnchor(
        _ anchor: InsertionAnchor,
        in collectionView: UICollectionView,
        pageMapper: PageMapper,
        readingMode: ReadingMode,
        insertedAtBeginning: Bool
    ) {
        // find new index for the anchored page
        guard let newIndex = pageMapper.getGlobalIndex(for: anchor.chapterId, page: anchor.pageInChapter) else {
            print("[InsertionStrategy] Could not find new index for anchor")
            return
        }
        
        let indexPath = IndexPath(item: newIndex, section: 0)
        
        // calculate offset adjustment
        if insertedAtBeginning {
            // content was inserted before our anchor
            let indexDelta = newIndex - anchor.globalIndex
            
            guard let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath) else {
                return
            }
            
            switch readingMode {
            case .infinite, .vertical:
                // adjust vertical offset
                let yDelta = layoutAttributes.frame.minY - anchor.visibleRect.minY
                collectionView.contentOffset.y = anchor.contentOffset.y + yDelta
                
            case .leftToRight, .rightToLeft:
                // adjust horizontal offset
                let xDelta = layoutAttributes.frame.minX - anchor.visibleRect.minX
                collectionView.contentOffset.x = anchor.contentOffset.x + xDelta
            }
        } else {
            // content was inserted after - no adjustment needed for scroll position
            // but ensure we're still at the same item
            switch readingMode {
            case .leftToRight, .rightToLeft:
                collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
            case .infinite, .vertical:
                collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
            }
        }
    }
}

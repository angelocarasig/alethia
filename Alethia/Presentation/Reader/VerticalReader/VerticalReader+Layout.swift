//
//  VerticalReader+Layout.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit

extension VerticalReaderController {
    final class VerticalLayout: UICollectionViewFlowLayout {
        var isInsertingCellsToTop = false
        private var oldContentHeight: CGFloat = 0
        
        override func prepare() {
            super.prepare()
            
            if isInsertingCellsToTop {
                oldContentHeight = collectionViewContentSize.height
            }
        }
        
        override func finalizeCollectionViewUpdates() {
            super.finalizeCollectionViewUpdates()
            
            if isInsertingCellsToTop, let collectionView = collectionView {
                // Calculate height difference
                let newContentHeight = collectionViewContentSize.height
                let heightDifference = newContentHeight - oldContentHeight
                
                // Adjust content offset to maintain position
                if heightDifference > 0 {
                    collectionView.contentOffset = CGPoint(
                        x: collectionView.contentOffset.x,
                        y: collectionView.contentOffset.y + heightDifference
                    )
                }
                
                isInsertingCellsToTop = false
            }
        }
    }
}

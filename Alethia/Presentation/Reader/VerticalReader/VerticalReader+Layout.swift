//
//  VerticalReader+Layout.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit

protocol OffsetPreservingLayout: NSObject {
    var isInsertingCellsToTop: Bool { get set }
}

extension VerticalReaderController {
    final class VerticalLayout: UICollectionViewFlowLayout, OffsetPreservingLayout {
        private var contentSizeBeforeInsertingToTop: CGSize?
        
        override init() {
            super.init()
            scrollDirection = .vertical
            
            sectionInset = .zero
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
        }
        
        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        var isInsertingCellsToTop: Bool = false {
            didSet {
                if isInsertingCellsToTop {
                    contentSizeBeforeInsertingToTop = collectionViewContentSize
                }
            }
        }
        
        override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
            return true
        }
        
        override func prepare() {
            super.prepare()
            
            sectionInset = .zero
            minimumLineSpacing = 0
            minimumInteritemSpacing = 0
            
            if let cv = collectionView {
                itemSize = cv.bounds.size
            }
            
            if isInsertingCellsToTop {
                if let collectionView = collectionView, let oldContentSize = contentSizeBeforeInsertingToTop {
                    UIView.performWithoutAnimation {
                        let newContentSize = self.collectionViewContentSize
                        let contentOffsetX = collectionView.contentOffset.x + (newContentSize.width - oldContentSize.width)
                        let contentOffsetY = collectionView.contentOffset.y + (newContentSize.height - oldContentSize.height)
                        let newOffset = CGPoint(x: contentOffsetX, y: contentOffsetY)
                        collectionView.contentOffset = newOffset
                    }
                }
                contentSizeBeforeInsertingToTop = nil
                isInsertingCellsToTop = false
            }
        }
    }
}

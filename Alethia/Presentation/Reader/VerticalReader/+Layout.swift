//
//  +Layout.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit

protocol OffsetPreservingLayout: NSObject {
    var isInsertingCellsToTop: Bool { get set }
}

class VerticalLayout: UICollectionViewFlowLayout, OffsetPreservingLayout {
    override init() {
        super.init()
        scrollDirection = .vertical
        minimumInteritemSpacing = 0
        minimumLineSpacing = 0 // spacing between items
        sectionInset = .zero
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
    
    private var contentSizeBeforeInsertingToTop: CGSize?
    
    // Override this method to ensure layout updates when bounds change
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func prepare() {
        super.prepare()
        
        if isInsertingCellsToTop {
            if let collectionView = collectionView, let oldContentSize = contentSizeBeforeInsertingToTop {
                // Create a transaction without animation to prevent any visual glitches
                UIView.performWithoutAnimation {
                    // Calculate the difference between the old and new content sizes
                    let newContentSize = self.collectionViewContentSize
                    
                    // Add the difference to the current content offset to maintain view position
                    let contentOffsetY = collectionView.contentOffset.y + (newContentSize.height - oldContentSize.height)
                    
                    // Set the new offset
                    collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: contentOffsetY)
                }
            }
            contentSizeBeforeInsertingToTop = nil
            isInsertingCellsToTop = false
        }
    }
    
    // Override to ensure layout attributes update with dynamic image heights
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let layoutAttributes = super.layoutAttributesForElements(in: rect)?.map { $0.copy() } as? [UICollectionViewLayoutAttributes]
        
        // Apply proper width to all cells
        layoutAttributes?.forEach { attribute in
            if attribute.representedElementCategory == .cell {
                attribute.frame.origin.x = 0
                attribute.frame.size.width = collectionView?.bounds.width ?? attribute.frame.size.width
            }
        }
        
        return layoutAttributes
    }
    
    // Override to adjust item size to collection view width
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return super.layoutAttributesForItem(at: indexPath)
        }
        
        // Set the width to match the collection view width
        attributes.frame.origin.x = 0
        attributes.frame.size.width = collectionView?.bounds.width ?? attributes.frame.size.width
        
        return attributes
    }
}

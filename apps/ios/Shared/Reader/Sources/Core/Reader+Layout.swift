//
//  Reader+Layout.swift
//  Reader
//
//  Created by Angelo Carasig on 21/10/2025.
//

import UIKit
import ChatLayout

// MARK: - ChatLayoutDelegate

extension Reader: ChatLayoutDelegate {
    
    public func shouldPresentHeader(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        return false
    }
    
    public func shouldPresentFooter(_ chatLayout: CollectionViewChatLayout, at sectionIndex: Int) -> Bool {
        return false
    }
    
    public func sizeForItem(_ chatLayout: CollectionViewChatLayout, of kind: ItemKind, at indexPath: IndexPath) -> ItemSize {
        guard indexPath.item < cachedImageURLs.count else {
            return .estimated(CGSize(width: collectionView.bounds.width, height: 500))
        }
        
        let urlString = cachedImageURLs[indexPath.item]
        
        switch configuration.readingMode {
        case .infinite:
            // use estimated size, let cell self-size based on aspect ratio
            let width = collectionView.bounds.width
            
            if let imageSize = imageSizes[urlString] {
                let aspectRatio = imageSize.height / imageSize.width
                let height = width * aspectRatio
                return .estimated(CGSize(width: width, height: height))
            }
            
            return .estimated(CGSize(width: width, height: 500))
            
        case .vertical:
            // use estimated size, let cell self-size
            let height = collectionView.bounds.height
            let width = collectionView.bounds.width
            
            if let imageSize = imageSizes[urlString] {
                let aspectRatio = imageSize.width / imageSize.height
                let calculatedWidth = height * aspectRatio
                let finalWidth = min(calculatedWidth, width)
                
                return .estimated(CGSize(width: finalWidth, height: height))
            }
            
            return .estimated(CGSize(width: width, height: height))
            
        case .leftToRight, .rightToLeft:
            // not used for horizontal modes (uses flow layout delegate instead)
            return .estimated(CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height))
        }
    }
    
    public func alignment(for kind: ItemKind, at indexPath: IndexPath, in sectionIndex: Int) -> ChatItemAlignment {
        switch configuration.readingMode {
        case .infinite:
            return .fullWidth
        case .vertical, .leftToRight, .rightToLeft:
            return .center
        }
    }
}

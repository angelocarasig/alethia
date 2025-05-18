//
//  VerticalReader+Computed.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit
import AsyncDisplayKit

extension VerticalReaderController {
    var collectionNode: ASCollectionNode {
        return node
    }
    
    var contentSize: CGSize {
        collectionNode.collectionViewLayout.collectionViewContentSize
    }
    
    var offset: CGFloat {
        collectionNode.contentOffset.y
    }
    
    var currentPoint: CGPoint {
        collectionNode.view.currentPoint
    }
    
    var currentPath: IndexPath? {
        collectionNode.view.pathAtCenterOfScreen
    }
    
    var pathAtCenterOfScreen: IndexPath? {
        collectionNode.view.pathAtCenterOfScreen
    }
}

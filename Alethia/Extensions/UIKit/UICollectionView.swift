//
//  UICollectionView.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit

extension UICollectionView {
    var currentPoint: CGPoint {
        .init(x: contentOffset.x + frame.midX, y: contentOffset.y + frame.midY)
    }
    
    var currentPath: IndexPath? {
        indexPathForItem(at: currentPoint)
    }
    
    var pathAtCenterOfScreen: IndexPath? {
        indexPathForItem(at: currentPoint)
    }
}

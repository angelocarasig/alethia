//
//  VerticalReader+Delegate.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import AsyncDisplayKit

extension VerticalReaderController: ASCollectionDelegate {
    func frameOfItem(at path: IndexPath) -> CGRect? {
        collectionNode.view.layoutAttributesForItem(at: path)?.frame
    }
}

extension VerticalReaderController: ASCollectionDelegateFlowLayout {
    func collectionNode(
        _ collectionNode: ASCollectionNode,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        // each cell = full screen (or collection-node bounds)
        return collectionNode.bounds.size
    }
}

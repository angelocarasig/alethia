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

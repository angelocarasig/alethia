//
//  +Delegate.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import SwiftUI
import UIKit
import AsyncDisplayKit

extension VerticalReaderController: ASCollectionDelegate {
    private class EmptyNode: ASCellNode {}
    
    func frameOfItem(at path: IndexPath) -> CGRect? {
        collectionNode.view.layoutAttributesForItem(at: path)?.frame
    }
    
    func collectionNode(_: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let item = dataSource.itemIdentifier(for: indexPath)
        guard let item else {
            return {
                EmptyNode()
            }
        }
        
        let position = resumptionPosition
        let height = view.frame.height * 0.70
        switch item {
        case let .page(page):
            return { [weak self] in
                let node = VerticalImageNode(page: page)
                node.delegate = self
                guard let pending = position,
                      pending.0 == page.pageNumber
                else {
                    return node
                }
                node.savedOffset = pending.1
                return node
            }
        case let .transition(transition):
            return {
                let node = ASCellNode(viewControllerBlock: {
                    let view = VerticalTransitionView(transition: transition)
                    let controller = UIHostingController(rootView: view)
                    return controller
                })
                node.style.width = ASDimensionMakeWithFraction(1)
                node.style.height = ASDimensionMake(height)
                return node
            }
        }
    }
}

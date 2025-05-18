//
//  VerticalImageNode.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit
import AsyncDisplayKit

final class VerticalImageNode: ASCellNode {
    var page: ReaderPage
    weak var delegate: VerticalReaderController?
    
    init(page: ReaderPage, delegate: VerticalReaderController) {
        self.page = page
        self.delegate = delegate
        
        super.init()
        
        // Create an image node with the page URL
        let imageNode = ASNetworkImageNode()
        imageNode.url = URL(string: page.url)
        imageNode.contentMode = .scaleAspectFit
        
        // Add the image node as a child
        addSubnode(imageNode)
        
        // Set layout specs
        layoutSpecBlock = { _, _ in
            return ASInsetLayoutSpec(
                insets: .zero,
                child: ASRatioLayoutSpec(ratio: 0.7, child: imageNode)
            )
        }
    }
}

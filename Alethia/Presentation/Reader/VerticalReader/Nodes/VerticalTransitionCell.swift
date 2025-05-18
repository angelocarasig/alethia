//
//  VerticalTransitionNode.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import AsyncDisplayKit

class VerticalTransitionNode: ASCellNode {
    var transition: ReaderTransition
    weak var delegate: VerticalReaderController?
    
    init(transition: ReaderTransition, delegate: VerticalReaderController) {
        self.transition = transition
        self.delegate = delegate
        super.init()
        
        // Create a text node for transition display
        let textNode = ASTextNode()
        textNode.attributedText = NSAttributedString(
            string: "Chapter \(transition.from.chapter.title) \(transition.to != nil ? "→ Chapter \(transition.to!.chapter.title)" : "End")",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.label
            ]
        )
        
        // Add the text node as a child
        addSubnode(textNode)
        
        // Set layout specs
        layoutSpecBlock = { _, _ in
            return ASCenterLayoutSpec(
                centeringOptions: .XY,
                sizingOptions: .minimumXY,
                child: ASInsetLayoutSpec(
                    insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20),
                    child: textNode
                )
            )
        }
    }
}

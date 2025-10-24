//
//  ReaderScrollHandler.swift
//  Reader
//
//  Created by Angelo Carasig on 21/10/2025.
//

import UIKit

/// handles scroll detection and triggers chapter loading for different reading modes
@MainActor
final class ReaderScrollHandler {
    func handleScroll(
        scrollView: UIScrollView,
        mode: ReadingMode,
        threshold: CGFloat,
        onLoadPrevious: @MainActor @escaping () -> Void,
        onLoadNext: @MainActor @escaping () -> Void
    ) {
        switch mode {
        case .leftToRight:
            handleHorizontalScroll(
                scrollView: scrollView,
                threshold: threshold,
                isRTL: false,
                onLoadPrevious: onLoadPrevious,
                onLoadNext: onLoadNext
            )
            
        case .rightToLeft:
            handleHorizontalScroll(
                scrollView: scrollView,
                threshold: threshold,
                isRTL: true,
                onLoadPrevious: onLoadPrevious,
                onLoadNext: onLoadNext
            )
            
        case .infinite, .vertical:
            handleVerticalScroll(
                scrollView: scrollView,
                threshold: threshold,
                onLoadPrevious: onLoadPrevious,
                onLoadNext: onLoadNext
            )
        }
    }
    
    private func handleHorizontalScroll(
        scrollView: UIScrollView,
        threshold: CGFloat,
        isRTL: Bool,
        onLoadPrevious: @escaping () -> Void,
        onLoadNext: @escaping () -> Void
    ) {
        let offsetX = scrollView.contentOffset.x
        let contentWidth = scrollView.contentSize.width
        let scrollViewWidth = scrollView.bounds.width
        
        if isRTL {
            // right to left: near right edge (low offsetX) = next chapter
            // near left edge (high offsetX) = previous chapter
            if offsetX < threshold {
                onLoadNext()
            }
            
            if offsetX + scrollViewWidth > contentWidth - threshold {
                onLoadPrevious()
            }
        } else {
            // left to right: near left edge (low offsetX) = previous chapter
            // near right edge (high offsetX) = next chapter
            if offsetX < threshold {
                onLoadPrevious()
            }
            
            if offsetX + scrollViewWidth > contentWidth - threshold {
                onLoadNext()
            }
        }
    }
    
    private func handleVerticalScroll(
        scrollView: UIScrollView,
        threshold: CGFloat,
        onLoadPrevious: @escaping () -> Void,
        onLoadNext: @escaping () -> Void
    ) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.bounds.height
        
        // check if near top for previous chapter
        if offsetY < threshold {
            onLoadPrevious()
        }
        
        // check if near bottom for next chapter
        if offsetY + scrollViewHeight > contentHeight - threshold {
            onLoadNext()
        }
    }
}

//
//  CollectionViewGrid.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import SwiftUI

struct CollectionViewGrid<Data, Content, Footer>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View, Footer: View {
    // Data
    let data: Data
    let content: (Data.Element) -> Content
    
    // Layout
    var columns: Int = 3
    var spacing: CGFloat = Constants.Spacing.minimal
    
    // UI
    var showsScrollIndicator: Bool = true
    
    // Footer
    let footer: Footer?
    
    // Callbacks
    var onReachedBottom: (() -> Void)?
    
    // State for bottom detection
    @State private var lastTriggerTime: Date?
    private let throttleInterval: TimeInterval = 2.0
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: showsScrollIndicator) {
            VStack(spacing: 0) {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(data) { item in
                        content(item)
                    }
                }
                
                // Footer view inside the ScrollView
                if let footer = footer {
                    footer
                }
            }
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            // Calculate if we've reached near the bottom
            let bottomEdge = geometry.contentOffset.y + geometry.containerSize.height
            let contentHeight = geometry.contentSize.height
            
            // Check if content is scrollable and if we're near bottom
            guard contentHeight > geometry.containerSize.height else { return false }
            
            return bottomEdge >= (contentHeight - 100)
        } action: { _, isNearBottom in
            if isNearBottom {
                triggerBottomReachedIfNeeded()
            }
        }
    }
    
    private func triggerBottomReachedIfNeeded() {
        let now = Date()
        
        // Check if we should throttle
        if let lastTime = lastTriggerTime {
            let timeSinceLastTrigger = now.timeIntervalSince(lastTime)
            guard timeSinceLastTrigger >= throttleInterval else { return }
        }
        
        // Update last trigger time and call the callback
        lastTriggerTime = now
        onReachedBottom?()
    }
}

// MARK: - Convenience Initializers
extension CollectionViewGrid where Footer == EmptyView {
    init(data: Data,
         columns: Int = 3,
         spacing: CGFloat = Constants.Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(
            data: data,
            content: content,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: nil,
            onReachedBottom: onReachedBottom
        )
    }
}

extension CollectionViewGrid {
    init(data: Data,
         columns: Int = 3,
         spacing: CGFloat = Constants.Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.init(
            data: data,
            content: content,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: footer(),
            onReachedBottom: onReachedBottom
        )
    }
}

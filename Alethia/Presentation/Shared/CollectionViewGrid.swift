//
//  CollectionViewGrid.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Core
import SwiftUI

struct CollectionViewGrid<Data, ID, Content, Footer>: View
where Data: RandomAccessCollection,
      Data.Element: Identifiable,
      ID: Hashable,
      Content: View,
      Footer: View {
    
    // Data
    let data: Data
    let content: (Data.Element) -> Content
    let id: KeyPath<Data.Element, ID>?
    
    // Layout
    var columns: Int = 3
    var spacing: CGFloat = .Spacing.minimal
    
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
                    if let idPath = id {
                        ForEach(data, id: idPath) { item in
                            content(item)
                        }
                    } else {
                        ForEach(data) { item in
                            content(item)
                        }
                    }
                }
                
                // Footer view inside the ScrollView
                if let footer = footer {
                    footer
                }
            }
        }
        .contentMargins(.trailing, .Padding.regular, for: .scrollContent)
        .onScrollGeometryChange(for: Bool.self) { geometry in
            let bottomEdge = geometry.contentOffset.y + geometry.containerSize.height
            let contentHeight = geometry.contentSize.height
            
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
        if let lastTime = lastTriggerTime {
            let timeSinceLastTrigger = now.timeIntervalSince(lastTime)
            guard timeSinceLastTrigger >= throttleInterval else { return }
        }
        lastTriggerTime = now
        onReachedBottom?()
    }
}

// MARK: - Convenience Initializers for Default ID
extension CollectionViewGrid where ID == Data.Element.ID {
    init(data: Data,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         footer: Footer?,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(
            data: data,
            content: content,
            id: nil,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: footer,
            onReachedBottom: onReachedBottom
        )
    }
}

// MARK: - Convenience Initializers for Custom ID (Refactored)
extension CollectionViewGrid {
    init(data: Data,
         id: KeyPath<Data.Element, ID>,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         footer: Footer?,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(
            data: data,
            content: content,
            id: id,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: footer,
            onReachedBottom: onReachedBottom
        )
    }
}

// MARK: - Empty Footer Convenience Initializers
extension CollectionViewGrid where Footer == EmptyView {
    init(data: Data,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) where ID == Data.Element.ID {
        self.init(
            data: data,
            content: content,
            id: nil,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: nil,
            onReachedBottom: onReachedBottom
        )
    }
    
    init(data: Data,
         id: KeyPath<Data.Element, ID>,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.init(
            data: data,
            content: content,
            id: id,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: nil,
            onReachedBottom: onReachedBottom
        )
    }
}

// MARK: - With Footer Builder Convenience Initializers
extension CollectionViewGrid where ID == Data.Element.ID {
    init(data: Data,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.init(
            data: data,
            content: content,
            id: nil,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: footer(),
            onReachedBottom: onReachedBottom
        )
    }
}

extension CollectionViewGrid {
    init(data: Data,
         id: KeyPath<Data.Element, ID>,
         columns: Int = 3,
         spacing: CGFloat = .Spacing.minimal,
         showsScrollIndicator: Bool = true,
         onReachedBottom: (() -> Void)? = nil,
         @ViewBuilder content: @escaping (Data.Element) -> Content,
         @ViewBuilder footer: () -> Footer) {
        self.init(
            data: data,
            content: content,
            id: id,
            columns: columns,
            spacing: spacing,
            showsScrollIndicator: showsScrollIndicator,
            footer: footer(),
            onReachedBottom: onReachedBottom
        )
    }
}

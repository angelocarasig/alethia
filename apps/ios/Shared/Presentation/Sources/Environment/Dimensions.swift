//
//  Dimensions.swift
//  Presentation
//
//  Created by Angelo Carasig on 16/6/2025.
//

import SwiftUI

private struct DimensionsKey: EnvironmentKey {
    static let defaultValue = Dimensions()
}

internal extension EnvironmentValues {
    var dimensions: Dimensions {
        get { self[DimensionsKey.self] }
        set { self[DimensionsKey.self] = newValue }
    }
}

@MainActor
internal struct Dimensions {
    enum Padding {
        static let minimal: CGFloat = 4
        static let regular: CGFloat = 8
        static let screen: CGFloat = 16
    }
    let padding = (
        minimal: Padding.minimal,
        regular: Padding.regular,
        screen: Padding.screen
    )
    
    enum Spacing {
        static let minimal: CGFloat = 4
        static let regular: CGFloat = 8
        static let large: CGFloat = 12
        static let toolbar: CGFloat = 16
        static let screen: CGFloat = 20
    }
    let spacing = (
        minimal: Spacing.minimal,
        regular: Spacing.regular,
        large: Spacing.large,
        toolbar: Spacing.toolbar,
        screen: Spacing.screen
    )
    
    enum CornerRadius {
        static let checkbox: CGFloat = 4
        static let card: CGFloat = 6
        static let regular: CGFloat = 8
        static let button: CGFloat = 12
        static let panel: CGFloat = 20
    }
    let cornerRadius = (
        checkbox: CornerRadius.checkbox,
        card: CornerRadius.card,
        regular: CornerRadius.regular,
        button: CornerRadius.button,
        panel: CornerRadius.panel
    )
    
    enum Icon {
        static let pill = CGSize(width: 20, height: 20)
        static let regular = CGSize(width: 40, height: 40)
        static let chapter = CGSize(width: 50, height: 50)
        static let large = CGSize(width: 75, height: 75)
    }
    let icon = (
        pill: Icon.pill,
        regular: Icon.regular,
        chapter: Icon.chapter,
        large: Icon.large
    )
    
    enum Offset {
        static let badge = CGSize(width: 0, height: -12)
        static let art = CGSize(width: 0, height: -12)
    }
    
    let offset = (
        badge: Offset.badge,
        art: Offset.art
    )
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.minimal), count: Defaults.gridColumns)
    }
}

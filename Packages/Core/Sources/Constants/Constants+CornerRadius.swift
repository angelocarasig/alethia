//
//  Constants+CornerRadius.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import SwiftUI

public extension Core.Constants {
    enum CornerRadius: CGFloat {
        case checkbox = 4
        case card = 6
        case regular = 8
        case button = 12
        case panel = 20
    }
}

public extension CGFloat {
    enum Corner {
        public static let checkbox = Core.Constants.CornerRadius.checkbox.rawValue
        public static let card = Core.Constants.CornerRadius.card.rawValue
        public static let regular = Core.Constants.CornerRadius.regular.rawValue
        public static let button = Core.Constants.CornerRadius.button.rawValue
        public static let panel = Core.Constants.CornerRadius.panel.rawValue
    }
}

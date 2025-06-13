//
//  Constants+Spacing.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import SwiftUI

public extension Core.Constants {
    enum Spacing: CGFloat {
        case minimal = 4
        case regular = 8
        case large = 12
        case toolbar = 16
    }
}

public extension CGFloat {
    enum Spacing {
        public static let minimal = Core.Constants.Spacing.minimal.rawValue
        public static let regular = Core.Constants.Spacing.regular.rawValue
        public static let large = Core.Constants.Spacing.large.rawValue
        public static let toolbar = Core.Constants.Spacing.toolbar.rawValue
    }
}

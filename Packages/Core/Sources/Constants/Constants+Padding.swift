//
//  Constants+Padding.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import SwiftUI

public extension Core.Constants {
    enum Padding: CGFloat {
        case minimal = 4
        case regular = 8
        case screen = 16
    }
}

public extension CGFloat {
    enum Padding {
        public static let minimal = Core.Constants.Padding.minimal.rawValue
        public static let regular = Core.Constants.Padding.regular.rawValue
        public static let screen = Core.Constants.Padding.screen.rawValue
    }
}

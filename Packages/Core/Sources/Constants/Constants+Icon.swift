//
//  Constants+Icon.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import SwiftUI

public extension Core.Constants {
    enum IconSize {
        case regular
        case large
        
        var size: CGSize {
            switch self {
            case .regular: return CGSize(width: 40, height: 40)
            case .large: return CGSize(width: 75, height: 75)
            }
        }
    }
}

public extension CGFloat {
    enum Icon {
        public static let regular = Core.Constants.IconSize.regular.size
        public static let large = Core.Constants.IconSize.large.size
    }
}


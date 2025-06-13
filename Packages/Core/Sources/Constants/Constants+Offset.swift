//
//  Constants+Offset.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import SwiftUI

public extension Core.Constants {
    enum Offset {
        case badge
        
        var size: CGSize {
            switch self {
            case .badge: return CGSize(width: 0, height: -12)
            }
        }
    }
}

public extension CGSize {
    enum Offset {
        public static let badge = Core.Constants.Offset.badge.size
    }
}

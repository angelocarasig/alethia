//
//  Orientation.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation

enum Orientation: String, Codable, CaseIterable {
    case LeftToRight
    case RightToLeft
    case Vertical
    case Infinite
    
    mutating func cycle() {
        switch self {
        case .LeftToRight:  self = .RightToLeft
        case .RightToLeft:  self = .Vertical
        case .Vertical:     self = .Infinite
        case .Infinite:     self = .LeftToRight
        }
    }
    
    var image: String {
        switch self {
        case .RightToLeft:
            return "rectangle.lefthalf.inset.filled.arrow.left"
        case .LeftToRight:
            return "rectangle.righthalf.inset.filled.arrow.right"
        case .Vertical:
            return "platter.filled.bottom.and.arrow.down.iphone"
        case .Infinite:
            return "arrow.down.app.fill"
        }
    }
}

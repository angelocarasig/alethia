//
//  Orientation.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

internal typealias Orientation = Domain.Models.Enums.Orientation

public extension Domain.Models.Enums {
    enum Orientation: String, Codable, CaseIterable {
        /// default value
        ///
        /// used in a use-case to conditionally return LTR (default horizontal)
        /// or infinite orientation (default vertical)
        case Default
        
        /// aka 'LTR'
        case LeftToRight
        
        /// aka 'RTL'
        case RightToLeft
        
        /// paginated vertical scrolling
        case Vertical
        
        /// an 'infinite' scroller where theres no spacing between pages
        case Infinite
        
        mutating func cycle() {
            switch self {
            case .LeftToRight:  self = .RightToLeft
            case .RightToLeft:  self = .Infinite
            case .Infinite:     self = .Vertical
            case .Vertical:     self = .LeftToRight
            default:
                self = .LeftToRight
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
            default:
                return "questionmark.circle.dashed"
            }
        }
        
        var isVertical: Bool {
            return self == .Vertical || self == .Infinite
        }
        
        var isHorizontal: Bool {
            return self == .LeftToRight || self == .RightToLeft
        }
    }
}

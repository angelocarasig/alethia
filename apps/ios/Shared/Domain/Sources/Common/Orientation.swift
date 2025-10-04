//
//  Orientation.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

public enum Orientation: Codable {
    case leftToRight
    case rightToLeft
    case vertical
    case infinite
    case unknown
    
    mutating func toggle() {
        self = switch self {
        case .leftToRight: .rightToLeft
        case .rightToLeft: .vertical
        case .vertical: .infinite
        case .infinite: .leftToRight
        case .unknown: .leftToRight
        }
    }
}

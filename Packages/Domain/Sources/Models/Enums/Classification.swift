//
//  Classification.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import SwiftUI
import GRDB

internal typealias Classification = Domain.Models.Enums.Classification

public extension Domain.Models.Enums {
    enum Classification: String, Codable, CaseIterable, DatabaseValueConvertible {
        case Unknown
        case Safe
        case Suggestive
        case Explicit
        
        var color: Color {
            switch self {
            case .Safe:         .green
            case .Suggestive:   .orange
            case .Explicit:     .red
            case .Unknown:      .gray
            }
        }
        
        var icon: String {
            switch self {
            case .Safe:         return "shield.checkerboard"
            case .Suggestive:   return "eye.fill"
            case .Explicit:     return "exclamationmark.triangle.fill"
            case .Unknown:      return "questionmark.circle.fill"
            }
        }
    }
}

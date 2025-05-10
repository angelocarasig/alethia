//
//  Classification.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import SwiftUI
import GRDB

enum Classification: String, Codable, CaseIterable, SQLExpressible {
    case Unknown
    case Safe
    case Suggestive
    case Explicit
    
    var color: Color {
        switch self {
        case .Safe:         .appGreen
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

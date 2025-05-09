//
//  Classification.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import SwiftUI

enum Classification: String, Codable, CaseIterable {
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
}

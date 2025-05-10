//
//  PublishStatus.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import SwiftUI
import GRDB

enum PublishStatus: String, Codable, CaseIterable, SQLExpressible {
    case Unknown
    case Ongoing
    case Completed
    case Hiatus
    case Cancelled
    
    var color: Color {
        switch self {
        case .Ongoing:      .appBlue
        case .Completed:    .appGreen
        case .Hiatus:       .orange
        case .Cancelled:    .red
        case .Unknown:      .gray
        }
    }
    
    var icon: String {
        switch self {
        case .Ongoing:      return "play.circle.fill"
        case .Completed:    return "checkmark.circle.fill"
        case .Hiatus:       return "pause.circle.fill"
        case .Cancelled:    return "xmark.circle.fill"
        case .Unknown:      return "questionmark.circle.fill"
        }
    }
}

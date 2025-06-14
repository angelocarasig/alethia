//
//  PublishStatus.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import SwiftUI
import GRDB

internal typealias PublishStatus = Domain.Models.Enums.PublishStatus

public extension Domain.Models.Enums {
    enum PublishStatus: String, Codable, CaseIterable, SQLExpressible {
        case Unknown
        case Ongoing
        case Completed
        case Hiatus
        case Cancelled
        
        var color: Color {
            switch self {
            case .Ongoing:      .blue
            case .Completed:    .green
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
}

//
//  PublishStatus.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import SwiftUI

enum PublishStatus: String, Codable, CaseIterable {
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
}

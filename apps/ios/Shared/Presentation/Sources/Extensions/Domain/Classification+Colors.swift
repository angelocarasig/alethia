//
//  Classification.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Domain
import SwiftUI

extension Classification {
    func themeColor(using theme: Theme) -> Color {
        switch self {
        case .Unknown:
            return theme.colors.foreground.opacity(0.5)
        case .Safe:
            return theme.colors.appGreen
        case .Suggestive:
            return theme.colors.appOrange
        case .Explicit:
            return theme.colors.appRed
        }
    }
}

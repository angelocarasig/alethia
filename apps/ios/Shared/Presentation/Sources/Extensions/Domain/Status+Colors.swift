//
//  Status.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Domain
import SwiftUI

extension Status {
    func themeColor(using theme: Theme) -> Color {
        switch self {
        case .Unknown:
            return theme.colors.foreground.opacity(0.5)
        case .Ongoing:
            return theme.colors.appBlue
        case .Completed:
            return theme.colors.appGreen
        case .Hiatus:
            return theme.colors.appOrange
        case .Cancelled:
            return theme.colors.appRed
        }
    }
}

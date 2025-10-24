//
//  Color+UIColor.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI
import UIKit

extension Color {
    /// converts SwiftUI Color to UIColor
    var uiColor: UIColor {
        UIColor(self)
    }
}

extension UIColor {
    /// converts UIColor to SwiftUI Color
    var color: Color {
        Color(self)
    }
}

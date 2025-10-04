//
//  View+Dimensions.swift
//  Presentation
//
//  Created by Angelo Carasig on 16/6/2025.
//

import SwiftUI

internal extension View {
    func frame(_ size: CGSize) -> some View {
        self.frame(width: size.width, height: size.height)
    }
}

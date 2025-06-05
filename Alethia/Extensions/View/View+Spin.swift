//
//  View+Spin.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import SwiftUI

private struct InfiniteRotation: ViewModifier {
    let speed: Double
    let clockwise: Bool
    
    @State private var rotate = false
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotate ? (clockwise ? 360 : -360) : 0))
            .animation(
                .linear(duration: speed)
                .repeatForever(autoreverses: false),
                value: rotate
            )
            .onAppear {
                rotate = true
            }
    }
}

extension View {
    /// Applies an infinite spinning animation to the view.
    /// - Parameters:
    ///   - speed: Time in seconds for one full rotation. Default is 1 second.
    ///   - clockwise: Direction of rotation. Default is `true` (clockwise).
    func spin(speed: Double = 1, clockwise: Bool = true) -> some View {
        self.modifier(InfiniteRotation(speed: speed, clockwise: clockwise))
    }
}

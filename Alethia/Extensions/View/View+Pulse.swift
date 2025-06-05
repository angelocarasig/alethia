//
//  View+Pulse.swift
//  Alethia
//
//  Created by Angelo Carasig on 6/5/2025.
//

import SwiftUI

private struct PulseEffect: ViewModifier {
    let scale: CGFloat
    let speed: Double
    let repeatForever: Bool
    
    @State private var pulsate = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulsate ? scale : 1)
            .animation(
                .easeInOut(duration: speed)
                .repeatForever(autoreverses: true),
                value: pulsate
            )
            .onAppear {
                pulsate = true
            }
    }
}

extension View {
    /// Applies a pulsing (scaling) animation to the view.
    /// - Parameters:
    ///   - scale: How much to scale during pulse. Default is 1.2.
    ///   - speed: Duration of one pulse cycle (in seconds). Default is 1.
    ///   - repeatForever: Whether the pulse should repeat forever. Default is true.
    func pulse(scale: CGFloat = 1.2, speed: Double = 1, repeatForever: Bool = true) -> some View {
        self.modifier(PulseEffect(scale: scale, speed: speed, repeatForever: repeatForever))
    }
}

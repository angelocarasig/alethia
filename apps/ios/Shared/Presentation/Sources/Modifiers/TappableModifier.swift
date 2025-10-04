//
//  TappableModifier.swift
//  Presentation
//
//  Created by Angelo Carasig on 9/6/2025.
//

import SwiftUI

private struct TappableModifier: ViewModifier {
    let action: () -> Void
    @State private var startLocation: CGPoint = .zero
    @State private var startTime: Date = .now
    @State private var isCancelled = false
    
    func body(content: Content) -> some View {
        content
            .pressable()
            .onTapGesture {
                action()
            }
    }
}

extension View {
    func tappable(action: @escaping () -> Void) -> some View {
        modifier(TappableModifier(action: action))
    }
}

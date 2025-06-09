//
//  View+Tappable.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import SwiftUI

private struct TappableModifier: ViewModifier {
    let action: () -> Void
    @State private var startLocation: CGPoint = .zero
    
    func body(content: Content) -> some View {
        content
            .pressable()
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        if startLocation == .zero {
                            startLocation = value.startLocation
                        }
                    }
                    .onEnded { value in
                        defer { startLocation = .zero }
                        
                        // Calculate total drag distance from start
                        let dragDistance = sqrt(
                            pow(value.location.x - startLocation.x, 2) +
                            pow(value.location.y - startLocation.y, 2)
                        )
                        
                        // More lenient threshold for horizontal scrolls
                        if dragDistance < 15 {
                            action()
                        }
                    }
            )
    }
}

extension View {
    func tappable(action: @escaping () -> Void) -> some View {
        modifier(TappableModifier(action: action))
    }
}

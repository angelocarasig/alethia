//
//  +BackgroundGradientView.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI

struct BackgroundGradientView: View {
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: theme.colors.background.opacity(0), location: 0),
                    .init(color: theme.colors.background, location: 1)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 800)
            
            theme.colors.background
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

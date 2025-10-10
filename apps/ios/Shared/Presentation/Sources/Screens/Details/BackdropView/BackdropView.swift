//
//  BackdropView.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Kingfisher

fileprivate let BACKGROUND_GRADIENT_BREAKPOINT: CGFloat = 600

struct BackdropView: View {
    @Environment(\.theme) private var theme
    
    let backdrop: URL
    
    var body: some View {
        GeometryReader { geometry in
            KFImage(backdrop)
                .placeholder { theme.colors.tint.shimmer() }
                .retry(maxCount: 5, interval: .seconds(2))
                .coverCache()
                .resizable()
                .fade(duration: 0.25)
                .scaledToFill()
                .frame(width: geometry.size.width, height: BACKGROUND_GRADIENT_BREAKPOINT)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, theme.colors.background]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
}

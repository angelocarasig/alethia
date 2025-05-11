//
//  BackdropView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI
import Kingfisher

fileprivate let BACKGROUND_GRADIENT_BREAKPOINT: CGFloat = 600

struct BackdropView: View {
    let cover: Cover?
    
    var body: some View {
        let cover = cover?.url ?? ""
        GeometryReader { geometry in
            KFImage(URL(string: cover))
                .placeholder { Color.secondary.shimmer() }
                .retry(maxCount: 5, interval: .seconds(2))
                .resizable()
                .fade(duration: 0.25)
                .scaledToFill()
                .id(cover)
                .frame(width: geometry.size.width, height: BACKGROUND_GRADIENT_BREAKPOINT)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.background]),
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
        }
    }
}

struct BackgroundGradientView: View {
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.background.opacity(0.0), location: 0.0),
                    .init(color: Color.background.opacity(1.0), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: BACKGROUND_GRADIENT_BREAKPOINT * 1.5)
            
            Color.background.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


//
//  BackdropView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI
import NukeUI

fileprivate let BACKGROUND_GRADIENT_BREAKPOINT: CGFloat = 800

struct BackdropView: View {
    let cover: Cover?
    
    var body: some View {
        let cover = cover?.url ?? ""
        GeometryReader { geometry in
            LazyImage(url: URL(string: cover)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
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
                        .id(cover)
                }
                else {
                    Color.gray.shimmer()
                }
            }
            .priority(.high)
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
            .frame(height: BACKGROUND_GRADIENT_BREAKPOINT)
            
            Color.background.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


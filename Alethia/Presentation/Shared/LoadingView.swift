//
//  LoadingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ContentUnavailableView {
            ModernSpinner()
                .frame(
                    width: Constants.Icon.Size.large,
                    height: Constants.Icon.Size.large
                )
        } description: {
            Text("Please Wait")
                .font(.title3)
                .padding(.top, Constants.Padding.screen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private struct ModernSpinner: View {
        @State private var isAnimating = false
        
        var body: some View {
            GeometryReader { geometry in
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width / 5, height: geometry.size.height / 5)
                        .scaleEffect(isAnimating ? 1 : 0.5)
                        .opacity(isAnimating ? 0.3 : 1)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height / 2
                        )
                        .offset(
                            x: cos(CGFloat(index) * .pi * 2 / 3) * geometry.size.width / 3,
                            y: sin(CGFloat(index) * .pi * 2 / 3) * geometry.size.width / 3
                        )
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LoadingView()
}

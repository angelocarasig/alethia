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
            EnhancedCircularSpinner()
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
    
    private struct EnhancedCircularSpinner: View {
        @State private var isAnimating = false
        
        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 0)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
    
}

//
//  DetailsLoadingView.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//


//
//  DetailsLoadingView.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI

struct DetailsLoadingView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
                Spacer().frame(height: 200)
                
                // cover skeleton
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .fill(theme.colors.tint)
                    .frame(width: 140, height: 200)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                    // title skeleton
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.tint)
                        .frame(height: 24)
                        .shimmer()
                    
                    // author skeleton
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.tint)
                        .frame(width: 120, height: 16)
                        .shimmer()
                }
                
                // action buttons skeleton
                HStack(spacing: dimensions.spacing.regular) {
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                        .fill(theme.colors.tint)
                        .frame(height: 50)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                        .fill(theme.colors.tint)
                        .frame(height: 50)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                        .fill(theme.colors.tint)
                        .frame(width: 50, height: 50)
                        .shimmer()
                }
                
                // synopsis skeleton
                VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                            .fill(theme.colors.tint)
                            .frame(height: 16)
                            .shimmer()
                    }
                    
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.tint)
                        .frame(width: 200, height: 14)
                        .shimmer()
                }
                
                // tags skeleton
                HStack(spacing: dimensions.spacing.regular) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule()
                            .fill(theme.colors.tint)
                            .frame(width: 80, height: 30)
                            .shimmer()
                    }
                }
                
                Divider()
                
                // chapters header skeleton
                VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.tint)
                        .frame(width: 150, height: 28)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.tint)
                        .frame(width: 100, height: 16)
                        .shimmer()
                }
                
                // chapters list skeleton
                VStack(spacing: dimensions.spacing.regular) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: dimensions.spacing.regular) {
                            RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                                .fill(theme.colors.tint)
                                .frame(dimensions.icon.chapter)
                                .shimmer()
                            
                            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                                RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                                    .fill(theme.colors.tint)
                                    .frame(height: 12)
                                    .shimmer()
                                
                                RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                                    .fill(theme.colors.tint)
                                    .frame(width: 180, height: 16)
                                    .shimmer()
                                
                                RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                                    .fill(theme.colors.tint)
                                    .frame(width: 100, height: 12)
                                    .shimmer()
                            }
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
        }
        .background(theme.colors.background)
    }
}

#Preview {
    DetailsLoadingView()
}

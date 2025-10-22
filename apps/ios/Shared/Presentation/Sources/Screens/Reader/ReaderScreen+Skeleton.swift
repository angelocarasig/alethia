//
//  ReaderScreen+Skeleton.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI

// MARK: - Loading Skeleton
extension ReaderScreen {
    @ViewBuilder
    var loadingOverlay: some View {
        VStack(spacing: 0) {
            topLoadingPlaceholder
            Spacer()
            bottomLoadingPlaceholder
        }
    }
    
    @ViewBuilder
    private var topLoadingPlaceholder: some View {
        HStack(alignment: .center, spacing: dimensions.spacing.large) {
            Circle()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 44, height: 44)
                .shimmer()
            
            Spacer()
            
            Capsule()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 120, height: 44)
                .shimmer()
            
            Spacer()
            
            Circle()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 44, height: 44)
                .shimmer()
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
        .padding(.bottom, dimensions.padding.screen)
    }
    
    @ViewBuilder
    private var bottomLoadingPlaceholder: some View {
        VStack(spacing: dimensions.spacing.screen) {
            sliderLoadingPlaceholder
            navigationLoadingPlaceholder
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
        .padding(.bottom, dimensions.padding.screen)
    }
    
    @ViewBuilder
    private var sliderLoadingPlaceholder: some View {
        HStack(spacing: dimensions.spacing.large) {
            Capsule()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 36, height: 36)
                .shimmer()
            
            Capsule()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(height: 4)
                .shimmer()
            
            Capsule()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 36, height: 36)
                .shimmer()
        }
    }
    
    @ViewBuilder
    private var navigationLoadingPlaceholder: some View {
        HStack(spacing: dimensions.spacing.large) {
            Circle()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 52, height: 52)
                .shimmer()
            
            Spacer()
            
            Capsule()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 100, height: 44)
                .shimmer()
            
            Spacer()
            
            Circle()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(width: 52, height: 52)
                .shimmer()
        }
    }
}

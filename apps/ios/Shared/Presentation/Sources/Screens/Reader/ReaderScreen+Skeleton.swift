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
            // close button should always be available
            Button {
                haptics.impact(.medium)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(.circle)
                    .contentShape(.circle)
            }
            
            Spacer()
            
            // show actual chapter info if available
            if let chapter = vm.currentChapter {
                VStack(spacing: dimensions.spacing.minimal) {
                    Text("Chapter \(Int(chapter.number))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // skeleton for page count
                    Capsule()
                        .fill(.white.opacity(0.3))
                        .frame(width: 40, height: 12)
                        .shimmer()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.regular)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
            } else {
                // full skeleton if no chapter info
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 120, height: 44)
                    .shimmer()
            }
            
            Spacer()
            
            Circle()
                .fill(.white.opacity(0.3))
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
                .fill(.white.opacity(0.3))
                .frame(width: 36, height: 36)
                .shimmer()
            
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(height: 4)
                .shimmer()
            
            Capsule()
                .fill(.white.opacity(0.3))
                .frame(width: 36, height: 36)
                .shimmer()
        }
    }
    
    @ViewBuilder
    private var navigationLoadingPlaceholder: some View {
        HStack(spacing: dimensions.spacing.large) {
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 52, height: 52)
                .shimmer()
            
            Spacer()
            
            // show actual chapter progress if available
            if let chapter = vm.currentChapter {
                VStack(spacing: dimensions.spacing.minimal) {
                    Text("Chapter \(Int(chapter.number))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("of \(vm.totalChapters)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.regular)
                .background(.ultraThinMaterial)
                .clipShape(.capsule)
            } else {
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 100, height: 44)
                    .shimmer()
            }
            
            Spacer()
            
            Circle()
                .fill(.white.opacity(0.3))
                .frame(width: 52, height: 52)
                .shimmer()
        }
    }
}

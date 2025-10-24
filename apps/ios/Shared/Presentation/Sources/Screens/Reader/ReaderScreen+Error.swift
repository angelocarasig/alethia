//
//  ReaderScreen+Error.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI
import Reader

// MARK: - Error Views
extension ReaderScreen {
    @ViewBuilder
    func initialErrorView(error: ReaderError) -> some View {
        VStack(spacing: 0) {
            HStack {
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
            }
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.top, dimensions.padding.screen)
            
            Spacer()
            
            ContentUnavailableView {
                Label(error.errorDescription ?? "Error", systemImage: "exclamationmark.triangle.fill")
            } description: {
                Text(error.failureReason ?? "An error occurred")
            } actions: {
                VStack(spacing: dimensions.spacing.regular) {
                    Button {
                        haptics.impact(.medium)
                        vm.retry()
                    } label: {
                        HStack(spacing: dimensions.spacing.regular) {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, dimensions.padding.screen * 2)
                        .padding(.vertical, dimensions.padding.regular)
                        .background(theme.colors.accent)
                        .clipShape(.capsule)
                    }
                    
                    Button {
                        haptics.impact(.light)
                        dismiss()
                    } label: {
                        Text("Go Back")
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
    }
}

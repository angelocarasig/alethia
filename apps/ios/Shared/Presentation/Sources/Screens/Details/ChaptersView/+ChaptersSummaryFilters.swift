//
//  +ChaptersSummaryFilters.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Domain

struct ChaptersSummaryFilters: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @Binding var filterMode: ChaptersSummaryView.FilterMode
    
    var body: some View {
        HStack(spacing: dimensions.spacing.regular) {
            ForEach(ChaptersSummaryView.FilterMode.allCases, id: \.self) { mode in
                filterButton(mode: mode)
            }
        }
    }
    
    @ViewBuilder
    private func filterButton(mode: ChaptersSummaryView.FilterMode) -> some View {
        Button {
            withAnimation(theme.animations.spring) {
                filterMode = mode
            }
        } label: {
            Text(mode.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(filterMode == mode ? theme.colors.background : theme.colors.foreground.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, dimensions.padding.regular)
                .padding(.vertical, dimensions.spacing.large)
                .background(filterMode == mode ? theme.colors.foreground : theme.colors.tint)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button, style: .continuous))
        }
    }
}

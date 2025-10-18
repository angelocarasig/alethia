//
//  SourceGridSortSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain

struct SourceGridSortSheet: View {
    @Binding var selectedSort: Search.Options.Sort
    @Binding var selectedDirection: SortDirection
    let availableSorts: [Search.Options.Sort]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
                    sortOptionsSection
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Sort Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    var sortOptionsSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            Text("SORT BY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.foreground.opacity(0.6))
            
            VStack(spacing: 0) {
                ForEach(availableSorts, id: \.self) { sortOption in
                    SortOptionRow(
                        sort: sortOption,
                        isSelected: selectedSort == sortOption,
                        direction: selectedDirection,
                        onSelect: { handleSortSelection(sortOption) }
                    )
                    
                    if sortOption != availableSorts.last {
                        Divider().padding(.leading, dimensions.padding.screen)
                    }
                }
            }
            .background(theme.colors.tint)
            .cornerRadius(dimensions.cornerRadius.button)
        }
    }
    
    func handleSortSelection(_ sortOption: Search.Options.Sort) {
        withAnimation(theme.animations.spring) {
            if selectedSort == sortOption {
                selectedDirection = selectedDirection == .ascending ? .descending : .ascending
            } else {
                selectedSort = sortOption
                selectedDirection = .descending
            }
        }
    }
}

// MARK: - sort option row

private struct SortOptionRow: View {
    let sort: Search.Options.Sort
    let isSelected: Bool
    let direction: SortDirection
    let onSelect: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: sortIcon)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.foreground.opacity(0.4))
                    .frame(width: 24)
                
                Text(sort.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(theme.colors.foreground)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: direction == .ascending ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(dimensions.padding.screen)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
    
    var sortIcon: String {
        switch sort {
        case .title: return "textformat"
        case .year: return "calendar"
        case .createdAt: return "clock"
        case .updatedAt: return "arrow.clockwise"
        case .relevance: return "star.fill"
        case .popularity: return "chart.line.uptrend.xyaxis"
        case .rating: return "star.leadinghalf.filled"
        case .chapters: return "book.fill"
        case .follows: return "heart.fill"
        }
    }
}

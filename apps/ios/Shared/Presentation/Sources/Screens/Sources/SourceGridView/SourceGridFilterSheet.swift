//
//  SourceGridFilterSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain
import Flow

struct SourceGridFilterSheet: View {
    let searchText: String
    @Binding var selectedYears: Set<String>
    @Binding var selectedStatuses: Set<Status>
    @Binding var selectedLanguages: Set<LanguageCode>
    @Binding var selectedRatings: Set<Classification>
    
    let availableYears: [String]
    let availableLanguages: [LanguageCode]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        !selectedYears.isEmpty ||
        !selectedStatuses.isEmpty ||
        !selectedLanguages.isEmpty ||
        !selectedRatings.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
                    if hasActiveFilters {
                        activeFiltersSection
                        Divider()
                    }
                    
                    if !searchText.isEmpty {
                        searchQuerySection
                        Divider()
                    }
                    
                    yearFilterSection
                    Divider()
                    statusFilterSection
                    Divider()
                    languageFilterSection
                    Divider()
                    ratingFilterSection
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Filter Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if hasActiveFilters {
                        Button("Clear All") {
                            withAnimation(theme.animations.spring) {
                                selectedYears.removeAll()
                                selectedStatuses.removeAll()
                                selectedLanguages.removeAll()
                                selectedRatings.removeAll()
                            }
                        }
                        .foregroundColor(theme.colors.appRed)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
}

// MARK: - sections

private extension SourceGridFilterSheet {
    var searchQuerySection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            Text("SEARCH QUERY")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(theme.colors.foreground.opacity(0.6))
            
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(theme.colors.accent)
                    .frame(width: 24)
                
                Text(searchText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.foreground)
                
                Spacer()
            }
            .padding(dimensions.padding.screen)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(dimensions.cornerRadius.button)
        }
    }
    
    var activeFiltersSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack {
                Text("ACTIVE FILTERS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                
                Spacer()
                
                Text("\(activeFilterCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, dimensions.padding.regular)
                    .padding(.vertical, dimensions.padding.minimal)
                    .background(theme.colors.accent)
                    .clipShape(.capsule)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(buildActiveFiltersList().enumerated()), id: \.offset) { index, filter in
                    ActiveFilterRow(
                        icon: filter.icon,
                        label: filter.label,
                        onRemove: filter.onRemove
                    )
                    
                    if index < buildActiveFiltersList().count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(theme.colors.tint)
            .cornerRadius(dimensions.cornerRadius.button)
        }
    }
    
    var yearFilterSection: some View {
        FilterSection(
            title: "YEAR",
            icon: "calendar",
            items: availableYears.map { FilterItem(id: $0, label: $0) },
            selectedItems: selectedYears,
            onToggle: { id in
                withAnimation(theme.animations.spring) {
                    if selectedYears.contains(id) {
                        selectedYears.remove(id)
                    } else {
                        selectedYears.insert(id)
                    }
                }
            }
        )
    }
    
    var statusFilterSection: some View {
        FilterSection(
            title: "STATUS",
            icon: "tag",
            items: Status.allCases.map { FilterItem(id: $0.rawValue, label: $0.rawValue) },
            selectedItems: Set(selectedStatuses.map { $0.rawValue }),
            onToggle: { id in
                withAnimation(theme.animations.spring) {
                    if let status = Status(rawValue: id) {
                        if selectedStatuses.contains(status) {
                            selectedStatuses.remove(status)
                        } else {
                            selectedStatuses.insert(status)
                        }
                    }
                }
            }
        )
    }
    
    var languageFilterSection: some View {
        FilterSection(
            title: "LANGUAGE",
            icon: "globe",
            items: availableLanguages.map {
                FilterItem(id: $0.rawValue, label: "\($0.flag) \($0.rawValue.uppercased())")
            },
            selectedItems: Set(selectedLanguages.map { $0.rawValue }),
            onToggle: { id in
                withAnimation(theme.animations.spring) {
                    let language = LanguageCode(id)
                    if selectedLanguages.contains(language) {
                        selectedLanguages.remove(language)
                    } else {
                        selectedLanguages.insert(language)
                    }
                }
            }
        )
    }
    
    var ratingFilterSection: some View {
        FilterSection(
            title: "CONTENT RATING",
            icon: "exclamationmark.shield",
            items: Classification.allCases.map { FilterItem(id: $0.rawValue, label: $0.rawValue) },
            selectedItems: Set(selectedRatings.map { $0.rawValue }),
            onToggle: { id in
                withAnimation(theme.animations.spring) {
                    if let rating = Classification(rawValue: id) {
                        if selectedRatings.contains(rating) {
                            selectedRatings.remove(rating)
                        } else {
                            selectedRatings.insert(rating)
                        }
                    }
                }
            }
        )
    }
}

// MARK: - computed properties

private extension SourceGridFilterSheet {
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        count += selectedYears.count
        count += selectedStatuses.count
        count += selectedLanguages.count
        count += selectedRatings.count
        return count
    }
}

// MARK: - helper methods

private extension SourceGridFilterSheet {
    func buildActiveFiltersList() -> [ActiveFilter] {
        var filters: [ActiveFilter] = []
        
        if !searchText.isEmpty {
            filters.append(ActiveFilter(
                icon: "magnifyingglass",
                label: searchText,
                onRemove: {}
            ))
        }
        
        for year in selectedYears {
            filters.append(ActiveFilter(
                icon: "calendar",
                label: "Year: \(year)",
                onRemove: {
                    withAnimation(theme.animations.spring) {
                        _ = selectedYears.remove(year)
                    }
                }
            ))
        }
        
        for status in selectedStatuses {
            filters.append(ActiveFilter(
                icon: "tag",
                label: "Status: \(status.rawValue)",
                onRemove: {
                    withAnimation(theme.animations.spring) {
                        _ = selectedStatuses.remove(status)
                    }
                }
            ))
        }
        
        for language in selectedLanguages {
            filters.append(ActiveFilter(
                icon: "globe",
                label: "Language: \(language.flag)",
                onRemove: {
                    withAnimation(theme.animations.spring) {
                        _ = selectedLanguages.remove(language)
                    }
                }
            ))
        }
        
        for rating in selectedRatings {
            filters.append(ActiveFilter(
                icon: "exclamationmark.shield",
                label: "Rating: \(rating.rawValue)",
                onRemove: {
                    withAnimation(theme.animations.spring) {
                        _ = selectedRatings.remove(rating)
                    }
                }
            ))
        }
        
        return filters
    }
}

// MARK: - models

private struct ActiveFilter {
    let icon: String
    let label: String
    let onRemove: () -> Void
}

private struct FilterItem: Identifiable {
    let id: String
    let label: String
}

// MARK: - active filter row

private struct ActiveFilterRow: View {
    let icon: String
    let label: String
    let onRemove: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: dimensions.spacing.regular) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(theme.colors.accent)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.foreground)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(theme.colors.foreground.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(dimensions.padding.screen)
    }
}

// MARK: - filter section

private struct FilterSection: View {
    let title: String
    let icon: String
    let items: [FilterItem]
    let selectedItems: Set<String>
    let onToggle: (String) -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                
                Spacer()
                
                if selectedItems.count > 0 {
                    Text("\(selectedItems.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, dimensions.padding.regular)
                        .padding(.vertical, dimensions.padding.minimal)
                        .background(theme.colors.accent.opacity(0.1))
                        .clipShape(.capsule)
                }
            }
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: dimensions.spacing.regular),
                    GridItem(.flexible(), spacing: dimensions.spacing.regular)
                ],
                spacing: dimensions.spacing.regular
            ) {
                ForEach(items) { item in
                    FilterOptionButton(
                        label: item.label,
                        isActive: selectedItems.contains(item.id),
                        onToggle: { onToggle(item.id) }
                    )
                }
            }
        }
    }
}

// MARK: - filter option button

private struct FilterOptionButton: View {
    let label: String
    let isActive: Bool
    let onToggle: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(isActive ? theme.colors.accent : theme.colors.foreground.opacity(0.3))
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(theme.colors.foreground)
                
                Spacer()
            }
            .padding(dimensions.padding.screen)
            .background(isActive ? theme.colors.accent.opacity(0.1) : theme.colors.tint)
            .cornerRadius(dimensions.cornerRadius.button)
        }
        .buttonStyle(.plain)
    }
}

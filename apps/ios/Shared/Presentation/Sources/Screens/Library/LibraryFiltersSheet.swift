//
//  LibraryFiltersSheet.swift
//  Presentation
//
//  Created by Assistant on 11/10/2025.
//

import SwiftUI
import Domain
import Flow

struct LibraryFiltersSheet: View {
    @Environment(LibraryViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.toolbar * 1.5) {
                    if vm.hasActiveFilters {
                        activeFiltersSection
                        Divider()
                    }
                    
                    sortSection
                    Divider()
                    
                    dateFilterSection(
                        title: "Added Date",
                        currentFilter: vm.addedDateFilter,
                        onFilterChange: {
                            vm.addedDateFilter = $0
                            vm.applyFilters()
                        }
                    )
                    Divider()
                    
                    dateFilterSection(
                        title: "Updated Date",
                        currentFilter: vm.updatedDateFilter,
                        onFilterChange: {
                            vm.updatedDateFilter = $0
                            vm.applyFilters()
                        }
                    )
                    Divider()
                    
                    publicationStatusSection
                    Divider()
                    
                    sourcesSection
                    Divider()
                    
                    toggleSection
                    
                    Spacer(minLength: dimensions.spacing.screen)
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Sections
    
    private var activeFiltersSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label("\(vm.activeFilterCount) Active Filters", systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(.headline)
                    .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Button("Clear All") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.resetFilters()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(theme.colors.appRed)
            }
            
            HFlow(spacing: dimensions.spacing.regular) {
                if !vm.searchText.isEmpty {
                    ActiveFilterChip(label: "Search: \(vm.searchText)") {
                        vm.searchText = ""
                        vm.applyFilters()
                    }
                }
                
                if vm.showUnreadOnly {
                    ActiveFilterChip(label: "Unread Only") {
                        vm.showUnreadOnly = false
                        vm.applyFilters()
                    }
                }
                
                if vm.showDownloadedOnly {
                    ActiveFilterChip(label: "Downloaded Only") {
                        vm.showDownloadedOnly = false
                        vm.applyFilters()
                    }
                }
                
                if vm.addedDateFilter != nil {
                    ActiveFilterChip(label: "Added Date Filter") {
                        vm.addedDateFilter = nil
                        vm.applyFilters()
                    }
                }
                
                if vm.updatedDateFilter != nil {
                    ActiveFilterChip(label: "Updated Date Filter") {
                        vm.updatedDateFilter = nil
                        vm.applyFilters()
                    }
                }
                
                ForEach(Array(vm.publicationStatus), id: \.self) { status in
                    ActiveFilterChip(label: status.rawValue) {
                        vm.publicationStatus.remove(status)
                        vm.applyFilters()
                    }
                }
                
                ForEach(Array(vm.selectedSources), id: \.self) { sourceId in
                    ActiveFilterChip(label: "Source #\(sourceId)") { // TODO: get actual source name
                        vm.selectedSources.remove(sourceId)
                        vm.applyFilters()
                    }
                }
            }
        }
    }
    
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Label("Sort", systemImage: "arrow.up.arrow.down")
                .font(.headline)
            
            VStack(spacing: dimensions.spacing.regular) {
                ForEach(LibrarySortField.allCases, id: \.self) { field in
                    SortOptionRow(
                        field: field,
                        isSelected: vm.sortField == field,
                        direction: vm.sortField == field ? vm.sortDirection : .ascending,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if vm.sortField == field {
                                    vm.sortDirection = vm.sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    vm.sortField = field
                                    vm.sortDirection = .ascending
                                }
                                vm.applyFilters()
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func dateFilterSection(
        title: String,
        currentFilter: DateFilter?,
        onFilterChange: @escaping (DateFilter?) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label(title, systemImage: "calendar")
                    .font(.headline)
                
                Spacer()
                
                if currentFilter != nil {
                    Button("Clear") {
                        withAnimation {
                            onFilterChange(nil)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.colors.appRed)
                }
            }
            
            Text("Date filtering will be implemented")
                .font(.caption)
                .foregroundStyle(.secondary)
            // TODO: implement date picker UI
        }
    }
    
    private var publicationStatusSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Label("Publication Status", systemImage: "book.closed")
                .font(.headline)
            
            HFlow(spacing: dimensions.spacing.regular) {
                ForEach(Status.allCases, id: \.self) { status in
                    FilterChip(
                        label: status.rawValue,
                        isSelected: vm.publicationStatus.contains(status),
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if vm.publicationStatus.contains(status) {
                                    vm.publicationStatus.remove(status)
                                } else {
                                    vm.publicationStatus.insert(status)
                                }
                                vm.applyFilters()
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Label("Sources", systemImage: "server.rack")
                .font(.headline)
            
            Text("Source filtering will be implemented")
                .font(.caption)
                .foregroundStyle(.secondary)
            // TODO: fetch actual sources from database
        }
    }
    
    private var toggleSection: some View {
        VStack(spacing: dimensions.spacing.toolbar) {
            Toggle(isOn: Binding(
                get: { vm.showUnreadOnly },
                set: {
                    vm.showUnreadOnly = $0
                    vm.applyFilters()
                }
            )) {
                Label("Unread Only", systemImage: "circle.badge.fill")
                    .font(.subheadline)
            }
            .tint(theme.colors.accent)
            
            Toggle(isOn: Binding(
                get: { vm.showDownloadedOnly },
                set: {
                    vm.showDownloadedOnly = $0
                    vm.applyFilters()
                }
            )) {
                Label("Downloaded Only", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline)
            }
            .tint(theme.colors.accent)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Reset") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    vm.resetFilters()
                }
            }
            .foregroundStyle(theme.colors.appRed)
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
}

// MARK: - Supporting Views

private struct SortOptionRow: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let field: LibrarySortField
    let isSelected: Bool
    let direction: Domain.SortDirection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: field.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: dimensions.icon.pill.width)
                
                Text(field.displayName)
                    .font(.subheadline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: direction == .ascending ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .foregroundStyle(isSelected ? theme.colors.foreground : .secondary)
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular + dimensions.padding.minimal / 2)
            .background(isSelected ? theme.colors.tint : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
        }
        .buttonStyle(.plain)
    }
}

private struct FilterChip: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(isSelected ? .white : theme.colors.foreground)
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.minimal * 1.5)
                .background(isSelected ? theme.colors.accent : theme.colors.tint)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ActiveFilterChip: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Text(label)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, dimensions.padding.regular)
        .padding(.vertical, dimensions.padding.minimal)
        .background(theme.colors.accent.opacity(0.8))
        .clipShape(Capsule())
    }
}

// MARK: - Extensions

extension Status: @retroactive CaseIterable {
    public static var allCases: [Status] {
        [.Unknown, .Ongoing, .Completed, .Hiatus, .Cancelled]
    }
}

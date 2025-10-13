//
//  LibraryFiltersSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 13/10/2025.
//

import SwiftUI
import Domain
import Flow

struct LibraryFiltersSheet: View {
    @Environment(LibraryViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var isSortExpanded = true
    @State private var isDatesExpanded = true
    @State private var isMetadataExpanded = true
    @State private var isQuickExpanded = true
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Active")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.bottom, dimensions.padding.regular)
                    
                    activeFiltersView
                    
                    Divider()
                        .padding(.vertical, dimensions.padding.screen)
                    
                    VStack(spacing: 0) {
                        sortSection
                        
                        Divider()
                            .padding(.vertical, dimensions.padding.screen)
                        
                        datesSection
                        
                        Divider()
                            .padding(.vertical, dimensions.padding.screen)
                        
                        metadataSection
                        
                        Divider()
                            .padding(.vertical, dimensions.padding.screen)
                        
                        quickFiltersSection
                    }
                }
                .padding()
            }
            .navigationTitle("Sorting and Filtering")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Text("Reset")
                        .foregroundColor(vm.hasActiveFilters ? theme.colors.accent : .secondary)
                        .tappable {
                            withAnimation(theme.animations.expand) {
                                vm.resetFilters()
                            }
                        }
                        .disabled(!vm.hasActiveFilters)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Text("Close")
                        .foregroundColor(theme.colors.accent)
                        .tappable { dismiss() }
                }
            }
        }
    }
}

// MARK: - Active Filters Display
private extension LibraryFiltersSheet {
    @ViewBuilder
    var activeFiltersView: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack(spacing: dimensions.spacing.regular) {
                Text("Sorting By").foregroundColor(.secondary)
                badge(vm.sortField.displayName, color: theme.colors.accent)
                Text("•").foregroundColor(.secondary).fontWeight(.medium)
                badge(vm.sortDirection.displayName, color: theme.colors.accent)
            }
            .font(.subheadline)
            .padding(.bottom, dimensions.padding.regular)
            
            HStack(spacing: dimensions.spacing.regular) {
                HStack(spacing: dimensions.spacing.minimal) {
                    Text("Active Filters").foregroundColor(.secondary)
                    if vm.activeFilterCount > 0 {
                        Text("\(vm.activeFilterCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, dimensions.padding.regular)
                            .padding(.vertical, dimensions.padding.minimal)
                            .background(theme.colors.appPurple.opacity(0.9))
                            .foregroundColor(.white)
                            .clipShape(.capsule)
                    }
                }
                
                if !vm.hasActiveFilters {
                    badge("None", color: theme.colors.tint)
                }
                
                HFlow(spacing: dimensions.spacing.minimal) {
                    ForEach(buildChips(), id: \.id) { chip in
                        Text(chip.name)
                            .lineLimit(1)
                            .fontWeight(.medium)
                            .padding(.horizontal, dimensions.padding.regular)
                            .padding(.vertical, dimensions.padding.minimal)
                            .background(chip.color)
                            .foregroundColor(.white)
                            .cornerRadius(dimensions.cornerRadius.button)
                            .contentShape(.capsule)
                            .tappable {
                                withAnimation(theme.animations.expand) {
                                    chip.remove()
                                }
                            }
                    }
                }
            }
            .font(.subheadline)
        }
    }
    
    @ViewBuilder
    func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .fontWeight(.medium)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, dimensions.padding.minimal)
            .background(color)
            .foregroundColor(theme.colors.foreground)
            .cornerRadius(dimensions.cornerRadius.button)
    }
    
    func buildChips() -> [FilterChip] {
        var chips: [FilterChip] = []
        
        if !vm.searchText.isEmpty {
            chips.append(FilterChip(
                id: "search",
                name: vm.searchText,
                color: theme.colors.accent,
                remove: { vm.clearSearchText() }
            ))
        }
        
        if vm.showUnreadOnly {
            chips.append(FilterChip(
                id: "unread",
                name: "Unread",
                color: theme.colors.appBlue,
                remove: { vm.showUnreadOnly = false; vm.applyFilters() }
            ))
        }
        
        if vm.showDownloadedOnly {
            chips.append(FilterChip(
                id: "downloaded",
                name: "Downloaded",
                color: theme.colors.appGreen,
                remove: { vm.showDownloadedOnly = false; vm.applyFilters() }
            ))
        }
        
        chips.append(contentsOf: vm.statuses.map { status in
            FilterChip(
                id: "status-\(status.rawValue)",
                name: status.rawValue,
                color: status.themeColor(using: theme),
                remove: { vm.statuses.remove(status); vm.applyFilters() }
            )
        })
        
        chips.append(contentsOf: vm.classifications.map { classification in
            FilterChip(
                id: "classification-\(classification.rawValue)",
                name: classification.rawValue,
                color: classification.themeColor(using: theme),
                remove: { vm.classifications.remove(classification); vm.applyFilters() }
            )
        })
        
        if vm.addedDateFilter.isActive {
            chips.append(FilterChip(
                id: "added-date",
                name: "Added: \(vm.addedDateFilter.displayText)",
                color: theme.colors.accent,
                remove: { vm.addedDateFilter = .none(); vm.applyFilters() }
            ))
        }
        
        if vm.updatedDateFilter.isActive {
            chips.append(FilterChip(
                id: "updated-date",
                name: "Updated: \(vm.updatedDateFilter.displayText)",
                color: theme.colors.accent,
                remove: { vm.updatedDateFilter = .none(); vm.applyFilters() }
            ))
        }
        
        return chips
    }
}

// MARK: - Section Header
private extension LibraryFiltersSheet {
    @ViewBuilder
    func sectionHeader(title: String, icon: String, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(theme.animations.expand) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: icon)
                    .foregroundStyle(theme.colors.accent)
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.foreground)
                Spacer()
                Image(systemName: "chevron.up")
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 0 : 180))
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Section
private extension LibraryFiltersSheet {
    @ViewBuilder
    var sortSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            sectionHeader(title: "Sort By", icon: "arrow.up.arrow.down.circle", isExpanded: $isSortExpanded)
            
            if isSortExpanded {
                ForEach(LibrarySortField.allCases, id: \.self) { field in
                    sortOption(field)
                }
            }
        }
    }
    
    @ViewBuilder
    func sortOption(_ field: LibrarySortField) -> some View {
        let isActive = vm.sortField == field
        
        HStack {
            Text(field.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            if isActive {
                Image(systemName: "arrow.up")
                    .rotationEffect(.degrees(vm.sortDirection == .ascending ? 0 : 180))
                    .animation(.easeInOut, value: vm.sortDirection)
            }
        }
        .padding()
        .foregroundColor(theme.colors.foreground)
        .background(isActive ? theme.colors.appBlue : theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .contentShape(.rect)
        .tappable {
            withAnimation(theme.animations.expand) {
                if isActive {
                    vm.sortDirection = vm.sortDirection == .ascending ? .descending : .ascending
                } else {
                    vm.sortField = field
                    vm.sortDirection = .descending
                }
                vm.applyFilters()
            }
        }
    }
}

// MARK: - Dates Section
private extension LibraryFiltersSheet {
    @ViewBuilder
    var datesSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            sectionHeader(title: "Dates", icon: "calendar", isExpanded: $isDatesExpanded)
            
            if isDatesExpanded {
                VStack(spacing: dimensions.spacing.large) {
                    dateFilterView(
                        title: "Added At",
                        filter: Binding(
                            get: { vm.addedDateFilter },
                            set: { vm.addedDateFilter = $0; vm.applyFilters() }
                        )
                    )
                    
                    Divider()
                    
                    dateFilterView(
                        title: "Last Updated",
                        filter: Binding(
                            get: { vm.updatedDateFilter },
                            set: { vm.updatedDateFilter = $0; vm.applyFilters() }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func dateFilterView(title: String, filter: Binding<DateFilter>) -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Text(title).font(.headline).fontWeight(.semibold)
                Spacer()
                Text("Clear")
                    .foregroundStyle(filter.wrappedValue.isActive ? theme.colors.accent : .secondary)
                    .tappable { filter.wrappedValue = .none() }
                    .disabled(!filter.wrappedValue.isActive)
            }
            
            HStack(spacing: dimensions.spacing.regular) {
                dateFilterOption("None", isSelected: isNone(filter.wrappedValue)) {
                    filter.wrappedValue = .none()
                }
                dateFilterOption("Before", isSelected: isBefore(filter.wrappedValue)) {
                    filter.wrappedValue = .before(Date())
                }
                dateFilterOption("After", isSelected: isAfter(filter.wrappedValue)) {
                    filter.wrappedValue = .after(Date())
                }
                dateFilterOption("Between", isSelected: isBetween(filter.wrappedValue)) {
                    filter.wrappedValue = .between(start: Date(), end: Date())
                }
            }
            
            Group {
                switch filter.wrappedValue.type {
                case .none:
                    Text("No Date Filter Applied").foregroundStyle(.secondary)
                case .before(let date):
                    DatePicker("Before Date", selection: dateBinding(for: date, filter: filter, update: { .before($0) }), displayedComponents: [.date])
                case .after(let date):
                    DatePicker("After Date", selection: dateBinding(for: date, filter: filter, update: { .after($0) }), displayedComponents: [.date])
                case .between(let start, let end):
                    VStack(spacing: dimensions.spacing.regular) {
                        DatePicker("Start Date", selection: dateBinding(for: start, filter: filter, update: { .between(start: $0, end: end) }), displayedComponents: [.date])
                        DatePicker("End Date", selection: dateBinding(for: end, filter: filter, update: { .between(start: start, end: $0) }), displayedComponents: [.date])
                    }
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
        }
    }
    
    @ViewBuilder
    func dateFilterOption(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding(.vertical, dimensions.padding.regular)
            .background(isSelected ? theme.colors.accent : theme.colors.tint)
            .foregroundColor(isSelected ? .white : theme.colors.foreground)
            .cornerRadius(dimensions.cornerRadius.regular)
            .contentShape(.rect)
            .tappable(action: action)
    }
    
    func isNone(_ filter: DateFilter) -> Bool {
        if case .none = filter.type { return true }
        return false
    }
    
    func isBefore(_ filter: DateFilter) -> Bool {
        if case .before = filter.type { return true }
        return false
    }
    
    func isAfter(_ filter: DateFilter) -> Bool {
        if case .after = filter.type { return true }
        return false
    }
    
    func isBetween(_ filter: DateFilter) -> Bool {
        if case .between = filter.type { return true }
        return false
    }
    
    func dateBinding(for date: Date, filter: Binding<DateFilter>, update: @escaping (Date) -> DateFilter) -> Binding<Date> {
        Binding(
            get: { date },
            set: { filter.wrappedValue = update($0) }
        )
    }
}

// MARK: - Metadata Section
private extension LibraryFiltersSheet {
    @ViewBuilder
    var metadataSection: some View {
        VStack(spacing: dimensions.spacing.large) {
            sectionHeader(title: "Metadata", icon: "info.circle", isExpanded: $isMetadataExpanded)
            
            if isMetadataExpanded {
                VStack(spacing: dimensions.spacing.large) {
                    metadataGrid(
                        title: "STATUS",
                        items: Status.allCases,
                        selected: vm.statuses,
                        icon: statusIcon,
                        onToggle: { status in
                            if vm.statuses.contains(status) {
                                vm.statuses.remove(status)
                            } else {
                                vm.statuses.insert(status)
                            }
                            vm.applyFilters()
                        },
                        onClear: {
                            vm.statuses.removeAll()
                            vm.applyFilters()
                        }
                    )
                    
                    metadataGrid(
                        title: "CLASSIFICATION",
                        items: Classification.allCases,
                        selected: vm.classifications,
                        icon: classificationIcon,
                        onToggle: { classification in
                            if vm.classifications.contains(classification) {
                                vm.classifications.remove(classification)
                            } else {
                                vm.classifications.insert(classification)
                            }
                            vm.applyFilters()
                        },
                        onClear: {
                            vm.classifications.removeAll()
                            vm.applyFilters()
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func metadataGrid<T: Hashable & RawRepresentable>(
        title: String,
        items: [T],
        selected: Set<T>,
        icon: @escaping (T) -> String,
        onToggle: @escaping (T) -> Void,
        onClear: @escaping () -> Void
    ) -> some View where T.RawValue == String {
        let columns = [GridItem(.flexible(), spacing: dimensions.spacing.regular), GridItem(.flexible(), spacing: dimensions.spacing.regular)]
        
        VStack(spacing: dimensions.spacing.regular) {
            HStack {
                Text(title).font(.caption).fontWeight(.semibold).foregroundColor(.secondary)
                Spacer()
                Text("Clear")
                    .foregroundStyle(!selected.isEmpty ? theme.colors.accent : .secondary)
                    .tappable {
                        withAnimation {
                            onClear()
                        }
                    }
                    .disabled(selected.isEmpty)
            }
            
            LazyVGrid(columns: columns, spacing: dimensions.spacing.large) {
                ForEach(items, id: \.self) { item in
                    let isSelected = selected.contains(item)
                    HStack(spacing: dimensions.spacing.regular) {
                        Image(systemName: icon(item)).symbolRenderingMode(.hierarchical)
                        Text(item.rawValue).font(.headline).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                    .padding(dimensions.padding.screen)
                    .background(isSelected ? theme.colors.accent : theme.colors.tint.opacity(0.5))
                    .cornerRadius(dimensions.cornerRadius.regular)
                    .contentShape(.rect)
                    .tappable {
                        withAnimation(theme.animations.expand) {
                            onToggle(item)
                        }
                    }
                }
            }
        }
    }
    
    func statusIcon(_ status: Status) -> String {
        switch status {
        case .Unknown: return "questionmark.circle"
        case .Ongoing: return "arrow.forward.circle"
        case .Completed: return "checkmark.circle"
        case .Hiatus: return "pause.circle"
        case .Cancelled: return "xmark.circle"
        }
    }
    
    func classificationIcon(_ classification: Classification) -> String {
        switch classification {
        case .Unknown: return "tag"
        case .Safe: return "checkmark.seal"
        case .Suggestive: return "flame"
        case .Explicit: return "xmark.seal"
        }
    }
}

// MARK: - Quick Filters Section
private extension LibraryFiltersSheet {
    @ViewBuilder
    var quickFiltersSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            sectionHeader(title: "Quick Filters", icon: "bolt.circle", isExpanded: $isQuickExpanded)
            
            if isQuickExpanded {
                VStack(spacing: dimensions.spacing.regular) {
                    quickToggle(
                        title: "Unread Only",
                        icon: "book.circle.fill",
                        isOn: Binding(
                            get: { vm.showUnreadOnly },
                            set: { vm.showUnreadOnly = $0; vm.applyFilters() }
                        )
                    )
                    
                    quickToggle(
                        title: "Downloaded Only",
                        icon: "arrow.down.circle.fill",
                        isOn: Binding(
                            get: { vm.showDownloadedOnly },
                            set: { vm.showDownloadedOnly = $0; vm.applyFilters() }
                        )
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    func quickToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(isOn.wrappedValue ? theme.colors.accent : .secondary)
            Text(title).font(.subheadline).fontWeight(.medium)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.colors.accent)
        }
        .padding()
        .background(isOn.wrappedValue ? theme.colors.accent.opacity(0.1) : theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
    }
}

// MARK: - Models
private struct FilterChip: Identifiable {
    let id: String
    let name: String
    let color: Color
    let remove: () -> Void
}

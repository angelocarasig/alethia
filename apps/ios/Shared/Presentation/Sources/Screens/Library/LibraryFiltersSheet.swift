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
    
    @State private var showDatePicker = false
    @State private var selectedDateFilter: DateFilterType = .addedDate
    @State private var datePickerDate = Date()
    
    enum DateFilterType {
        case addedDate
        case updatedDate
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.toolbar * 1.5) {
                    if vm.hasActiveFilters {
                        activeFiltersSection
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Divider()
                    }
                    
                    sortSection
                    Divider()
                    
                    dateFilterSection(
                        title: "Added Date",
                        icon: "calendar.badge.plus",
                        currentFilter: vm.addedDateFilter,
                        filterType: .addedDate
                    )
                    Divider()
                    
                    dateFilterSection(
                        title: "Updated Date",
                        icon: "calendar.badge.clock",
                        currentFilter: vm.updatedDateFilter,
                        filterType: .updatedDate
                    )
                    Divider()
                    
                    publicationStatusSection
                    Divider()
                    
                    sourcesSection
                    Divider()
                    
                    toggleSection
                    
                    filterPresetsSection
                    
                    Spacer(minLength: dimensions.spacing.screen)
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showDatePicker) {
                datePicker
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Sections
    
    private var activeFiltersSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label {
                    HStack(spacing: dimensions.spacing.minimal) {
                        Text("\(vm.activeFilterCount)")
                            .fontWeight(.bold)
                            .contentTransition(.numericText())
                        Text("Active Filters")
                    }
                } icon: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                }
                .font(.headline)
                .foregroundColor(theme.colors.accent)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.resetFilters()
                    }
                } label: {
                    HStack(spacing: dimensions.spacing.minimal) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                        Text("Clear All")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(theme.colors.appRed)
            }
            
            HFlow(spacing: dimensions.spacing.regular) {
                ForEach(buildActiveFilterChips(), id: \.id) { chip in
                    ActiveFilterChip(
                        icon: chip.icon,
                        label: chip.label,
                        color: chip.color
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            chip.onRemove()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: vm.activeFilterCount)
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
                                    // toggle direction if same field
                                    vm.sortDirection = vm.sortDirection == .ascending ? .descending : .ascending
                                } else {
                                    // change field and reset to ascending
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
        icon: String,
        currentFilter: DateFilter?,
        filterType: DateFilterType
    ) -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                Spacer()
                
                if currentFilter != nil {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            switch filterType {
                            case .addedDate:
                                vm.addedDateFilter = nil
                            case .updatedDate:
                                vm.updatedDateFilter = nil
                            }
                            vm.applyFilters()
                        }
                    } label: {
                        Text("Clear")
                            .font(.subheadline)
                            .foregroundStyle(theme.colors.appRed)
                    }
                }
            }
            
            HStack(spacing: dimensions.spacing.regular) {
                DatePresetButton(label: "Today", systemImage: "sun.max") {
                    setDateFilter(filterType: filterType, date: Date(), isAfter: true)
                }
                
                DatePresetButton(label: "This Week", systemImage: "calendar.day.timeline.left") {
                    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                    setDateFilter(filterType: filterType, date: weekAgo, isAfter: true)
                }
                
                DatePresetButton(label: "This Month", systemImage: "calendar") {
                    let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                    setDateFilter(filterType: filterType, date: monthAgo, isAfter: true)
                }
                
                DatePresetButton(label: "Custom", systemImage: "calendar.badge.plus") {
                    selectedDateFilter = filterType
                    showDatePicker = true
                }
            }
            
            if let filter = currentFilter {
                CurrentDateFilter(filter: filter)
            }
        }
    }
    
    private var publicationStatusSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label("Publication Status", systemImage: "book.closed")
                    .font(.headline)
                
                Spacer()
                
                if !vm.publicationStatus.isEmpty {
                    Text("\(vm.publicationStatus.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, dimensions.padding.regular)
                        .padding(.vertical, dimensions.padding.minimal)
                        .background(theme.colors.accent)
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                        .contentTransition(.numericText())
                }
            }
            
            HFlow(spacing: dimensions.spacing.regular) {
                ForEach(Status.allCases, id: \.self) { status in
                    FilterChip(
                        label: status.rawValue,
                        icon: iconForStatus(status),
                        isSelected: vm.publicationStatus.contains(status),
                        color: status.themeColor(using: theme),
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
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            HStack {
                Label("Sources", systemImage: "server.rack")
                    .font(.headline)
                
                Spacer()
                
                if !vm.selectedSources.isEmpty {
                    Text("\(vm.selectedSources.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, dimensions.padding.regular)
                        .padding(.vertical, dimensions.padding.minimal)
                        .background(theme.colors.accent)
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                        .contentTransition(.numericText())
                }
            }
            
            Text("Source filtering will be implemented")
                .font(.caption)
                .foregroundStyle(.secondary)
            // TODO: fetch actual sources from database with search
        }
    }
    
    private var toggleSection: some View {
        VStack(spacing: dimensions.spacing.toolbar) {
            ToggleRow(
                isOn: Binding(
                    get: { vm.showUnreadOnly },
                    set: { newValue in
                        vm.showUnreadOnly = newValue
                        vm.applyFilters()
                    }
                ),
                icon: "circle.badge.fill",
                title: "Unread Only",
                subtitle: "Show only manga with unread chapters"
            )
            
            ToggleRow(
                isOn: Binding(
                    get: { vm.showDownloadedOnly },
                    set: { newValue in
                        vm.showDownloadedOnly = newValue
                        vm.applyFilters()
                    }
                ),
                icon: "arrow.down.circle.fill",
                title: "Downloaded Only",
                subtitle: "Show only manga with downloaded chapters"
            )
        }
    }
    
    private var filterPresetsSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Label("Quick Presets", systemImage: "star")
                .font(.headline)
            
            VStack(spacing: dimensions.spacing.regular) {
                PresetButton(
                    title: "Currently Reading",
                    description: "Unread manga updated in the last month",
                    icon: "book",
                    color: theme.colors.appBlue
                ) {
                    applyPreset(
                        showUnreadOnly: true,
                        updatedDate: .after(Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date())
                    )
                    dismiss()
                }
                
                PresetButton(
                    title: "New Additions",
                    description: "Added in the last week",
                    icon: "sparkles",
                    color: theme.colors.appGreen
                ) {
                    applyPreset(
                        addedDate: .after(Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())
                    )
                    dismiss()
                }
                
                PresetButton(
                    title: "Completed Series",
                    description: "All completed manga",
                    icon: "checkmark.seal",
                    color: theme.colors.appPurple
                ) {
                    applyPreset(
                        publicationStatus: [.Completed]
                    )
                    dismiss()
                }
            }
        }
    }
    
    private var datePicker: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $datePickerDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDatePicker = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        setDateFilter(
                            filterType: selectedDateFilter,
                            date: datePickerDate,
                            isAfter: true
                        )
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    vm.resetFilters()
                }
            } label: {
                Text("Reset")
                    .foregroundStyle(theme.colors.appRed)
            }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Helper Methods
    
    private func setDateFilter(filterType: DateFilterType, date: Date, isAfter: Bool) {
        let filter = isAfter ? DateFilter.after(date) : DateFilter.before(date)
        switch filterType {
        case .addedDate:
            vm.addedDateFilter = filter
        case .updatedDate:
            vm.updatedDateFilter = filter
        }
        vm.applyFilters()
    }
    
    private func applyPreset(
        showUnreadOnly: Bool = false,
        publicationStatus: Set<Status> = [],
        addedDate: DateFilter? = nil,
        updatedDate: DateFilter? = nil
    ) {
        vm.showUnreadOnly = showUnreadOnly
        vm.publicationStatus = publicationStatus
        vm.addedDateFilter = addedDate
        vm.updatedDateFilter = updatedDate
        vm.applyFilters()
    }
    
    private func iconForStatus(_ status: Status) -> String {
        switch status {
        case .Unknown: return "questionmark.circle"
        case .Ongoing: return "arrow.forward.circle"
        case .Completed: return "checkmark.circle"
        case .Hiatus: return "pause.circle"
        case .Cancelled: return "xmark.circle"
        }
    }
    
    private func buildActiveFilterChips() -> [FilterChipData] {
        var chips: [FilterChipData] = []
        
        if !vm.searchText.isEmpty {
            chips.append(FilterChipData(
                id: "search",
                icon: "magnifyingglass",
                label: "Search: \(vm.searchText)",
                color: theme.colors.accent,
                onRemove: {
                    vm.searchText = ""
                    vm.applyFilters()
                }
            ))
        }
        
        if vm.showUnreadOnly {
            chips.append(FilterChipData(
                id: "unread",
                icon: "circle.badge",
                label: "Unread Only",
                color: theme.colors.appBlue,
                onRemove: {
                    vm.showUnreadOnly = false
                    vm.applyFilters()
                }
            ))
        }
        
        if vm.showDownloadedOnly {
            chips.append(FilterChipData(
                id: "downloaded",
                icon: "arrow.down.circle",
                label: "Downloaded",
                color: theme.colors.appGreen,
                onRemove: {
                    vm.showDownloadedOnly = false
                    vm.applyFilters()
                }
            ))
        }
        
        for status in vm.publicationStatus {
            chips.append(FilterChipData(
                id: "status-\(status.rawValue)",
                icon: iconForStatus(status),
                label: status.rawValue,
                color: status.themeColor(using: theme),
                onRemove: {
                    vm.publicationStatus.remove(status)
                    vm.applyFilters()
                }
            ))
        }
        
        if vm.addedDateFilter != nil {
            chips.append(FilterChipData(
                id: "added-date",
                icon: "calendar.badge.plus",
                label: "Added Date",
                color: theme.colors.accent,
                onRemove: {
                    vm.addedDateFilter = nil
                    vm.applyFilters()
                }
            ))
        }
        
        if vm.updatedDateFilter != nil {
            chips.append(FilterChipData(
                id: "updated-date",
                icon: "calendar.badge.clock",
                label: "Updated Date",
                color: theme.colors.accent,
                onRemove: {
                    vm.updatedDateFilter = nil
                    vm.applyFilters()
                }
            ))
        }
        
        return chips
    }
    
    struct FilterChipData {
        let id: String
        let icon: String
        let label: String
        let color: Color
        let onRemove: () -> Void
    }
}

// MARK: - Supporting Views (remain the same)

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
                    .foregroundStyle(isSelected ? theme.colors.accent : .secondary)
                    .frame(width: dimensions.icon.pill.width)
                    .contentTransition(.symbolEffect)
                
                Text(field.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: direction == .ascending ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(theme.colors.accent)
                        .transition(.scale.combined(with: .opacity))
                        .contentTransition(.symbolEffect)
                }
            }
            .foregroundStyle(isSelected ? theme.colors.foreground : .secondary)
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular + dimensions.padding.minimal / 2)
            .background(isSelected ? theme.colors.accent.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
            .overlay(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .strokeBorder(isSelected ? theme.colors.accent.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterChip: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let label: String
    let icon: String?
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(label: String, icon: String? = nil, isSelected: Bool, color: Color? = nil, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.isSelected = isSelected
        self.color = color ?? Color.accentColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: dimensions.spacing.minimal) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline)
            }
            .foregroundStyle(isSelected ? .white : theme.colors.foreground)
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.minimal * 1.5)
            .background(isSelected ? color : theme.colors.tint)
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

private struct ActiveFilterChip: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let icon: String?
    let label: String
    let color: Color
    let onRemove: () -> Void
    
    init(icon: String? = nil, label: String, color: Color? = nil, onRemove: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.color = color ?? Color.accentColor
        self.onRemove = onRemove
    }
    
    var body: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            
            Text(label)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, dimensions.padding.regular)
        .padding(.vertical, dimensions.padding.minimal)
        .background(color.opacity(0.8))
        .clipShape(.capsule)
    }
}

private struct DatePresetButton: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let label: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: systemImage)
                    .font(.body)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, dimensions.padding.regular)
            .background(theme.colors.tint)
            .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
        }
        .buttonStyle(.plain)
    }
}

private struct CurrentDateFilter: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let filter: DateFilter
    
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.checkmark")
                .font(.caption)
                .foregroundStyle(theme.colors.appGreen)
            
            Text(filterDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(dimensions.padding.regular)
        .background(theme.colors.tint.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
    }
    
    private var filterDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        switch filter.type {
        case .before(let date):
            return "Before \(formatter.string(from: date))"
        case .after(let date):
            return "After \(formatter.string(from: date))"
        case .between(let start, let end):
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

private struct ToggleRow: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @Binding var isOn: Bool
    let icon: String
    let title: String
    let subtitle: String?
    
    init(isOn: Binding<Bool>, icon: String, title: String, subtitle: String? = nil) {
        self._isOn = isOn
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(isOn ? theme.colors.accent : .secondary)
                    .contentTransition(.symbolEffect)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .tint(theme.colors.accent)
    }
}

private struct PresetButton: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.colors.foreground)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(dimensions.padding.screen)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.button))
            .overlay(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Extensions

extension Status: @retroactive CaseIterable {
    public static var allCases: [Status] {
        [.Unknown, .Ongoing, .Completed, .Hiatus, .Cancelled]
    }
}

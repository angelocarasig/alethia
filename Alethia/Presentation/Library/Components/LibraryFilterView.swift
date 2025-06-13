//
//  LibraryFilterView.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Core
import SwiftUI
import Flow

struct LibraryFilterView: View {
    @EnvironmentObject private var vm: LibraryViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Filters")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Reset to Default")
                        .foregroundColor(vm.filters.isEmpty ? .secondary : .accentColor)
                        .tappable { vm.filters.reset() }
                        .disabled(vm.filters.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, .Padding.regular)

                HStack(spacing: .Spacing.regular) {
                    Text("Sorting By")
                        .foregroundColor(.secondary)
                    Text(vm.filters.sortType.rawValue)
                        .fontWeight(.medium)
                        .padding(.horizontal, .Padding.regular)
                        .padding(.vertical, .Padding.minimal)
                        .background(Color.appBlue)
                        .foregroundColor(.text)
                        .cornerRadius(.Corner.button)
                    Text("•")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(vm.filters.sortDirection.rawValue)
                        .fontWeight(.medium)
                        .padding(.horizontal, .Padding.regular)
                        .padding(.vertical, .Padding.minimal)
                        .background(Color.appBlue)
                        .foregroundColor(.text)
                        .cornerRadius(.Corner.button)
                }
                .font(.subheadline)
                .padding(.bottom, .Padding.regular)

                HStack(spacing: .Spacing.regular) {
                    Text("Active Filters")
                        .foregroundColor(.secondary)
                    if vm.filters.isEmpty {
                        Text("None")
                            .fontWeight(.medium)
                            .padding(.horizontal, .Padding.regular)
                            .padding(.vertical, .Padding.minimal)
                            .background(Color.tint)
                            .foregroundColor(.text)
                            .cornerRadius(.Corner.button)
                    }
                    HFlow {
                        ForEach(vm.filters.activeFilters, id: \.id) { filter in
                            Text(filter.name)
                                .fontWeight(.medium)
                                .padding(.horizontal, .Padding.regular)
                                .padding(.vertical, .Padding.minimal)
                                .background(filter.color)
                                .foregroundColor(.text)
                                .cornerRadius(.Corner.button)
                        }
                    }
                }
                .font(.subheadline)
            }

            Divider().padding(.vertical, .Padding.regular)
            
            VStack(spacing: .Spacing.large) {
                SortOptions()
                
                Divider().padding(.vertical, .Padding.regular)
                
                FilterOptions()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    @ViewBuilder
    private func SortOptions() -> some View {
        VStack {
            Text("Sort By")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(LibrarySortType.allCases) { sortType in
                let isActive = vm.filters.sortType == sortType
                HStack {
                    Text(sortType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if isActive {
                        Image(systemName: "arrow.up")
                            .rotationEffect(.degrees(vm.filters.sortDirection == .ascending ? 0 : 180))
                            .animation(.easeInOut, value: vm.filters.sortDirection)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .foregroundColor(.text)
                .background(isActive ? Color.appBlue : Color.tint)
                .cornerRadius(.Corner.button)
                .contentShape(.rect)
                .tappable {
                    withAnimation {
                        if isActive {
                            vm.filters.sortDirection.toggle()
                        } else {
                            vm.filters.sortType = sortType
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func FilterOptions() -> some View {
        AddedDateFilter()
        Divider()
        UpdatedDateFilter()
        Divider()
        ContentTypeFilterView()
    }

    @ViewBuilder
    private func AddedDateFilter() -> some View {
        DateFilter(
            title: "Added At",
            canClear: vm.filters.addedAt != .none,
            onClear: { vm.clearFilter(for: .addedAt) },
            date: $vm.filters.addedAt
        )
    }

    @ViewBuilder
    private func UpdatedDateFilter() -> some View {
        DateFilter(
            title: "Last Updated",
            canClear: vm.filters.updatedAt != .none,
            onClear: { vm.clearFilter(for: .updatedAt) },
            date: $vm.filters.updatedAt
        )
    }

    @ViewBuilder
    private func DateFilter(title: String, canClear: Bool, onClear: @escaping () -> Void, date: Binding<LibraryDate>) -> some View {
        VStack(alignment: .leading, spacing: .Spacing.large) {
            HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("Clear")
                    .foregroundStyle(canClear ? Color.accentColor : Color.secondary)
                    .tappable { onClear() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Date", selection: date) {
                ForEach(LibraryDate.allCases, id: \.self) { option in
                    Text(option.displayText).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch date.wrappedValue {
                case .none:
                    Text("No Date Filter Applied")
                        .foregroundStyle(.secondary)
                case .before(let boundDate):
                    DatePicker(
                        "Before Date",
                        selection: Binding(
                            get: { boundDate },
                            set: { new in date.wrappedValue = .before(date: new) }
                        ),
                        displayedComponents: [.date]
                    )
                case .after(let boundDate):
                    DatePicker(
                        "After Date",
                        selection: Binding(
                            get: { boundDate },
                            set: { new in date.wrappedValue = .after(date: new) }
                        ),
                        displayedComponents: [.date]
                    )
                case .between(let start, let end):
                    VStack(spacing: .Spacing.regular) {
                        DatePicker(
                            "Start Date",
                            selection: Binding(
                                get: { start },
                                set: { new in date.wrappedValue = .between(start: new, end: end) }
                            ),
                            displayedComponents: [.date]
                        )
                        DatePicker(
                            "End Date",
                            selection: Binding(
                                get: { end },
                                set: { new in date.wrappedValue = .between(start: start, end: new) }
                            ),
                            displayedComponents: [.date]
                        )
                    }
                }
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.top, .Padding.regular)
        }
    }

    @ViewBuilder
    private func ContentTypeFilterView() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        VStack {
            HStack {
                Text("Metadata")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("Clear")
                    .foregroundStyle(vm.filters.isPresent(.metadata) ? Color.accentColor : Color.secondary)
                    .tappable { vm.clearFilter(for: .metadata) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("STATUS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: .Spacing.large) {
                ForEach(PublishStatus.allCases, id: \.rawValue) { status in
                    HStack(spacing: .Spacing.regular) {
                        Image(systemName: status.icon)
                        Text(status.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.Padding.screen)
                    .background(vm.filters.publishStatus.contains(status) ? status.color : .tint.opacity(0.5))
                    .cornerRadius(.Corner.regular)
                    .contentShape(.rect)
                    .tappable { vm.togglePublishStatus(status: status) }
                }
            }

            Spacer().frame(height: 25)

            Text("CLASSIFICATION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: .Spacing.large) {
                ForEach(Classification.allCases, id: \.rawValue) { classification in
                    HStack(spacing: .Spacing.regular) {
                        Image(systemName: classification.icon)
                        Text(classification.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.Padding.screen)
                    .background(vm.filters.classification.contains(classification) ? classification.color : .tint.opacity(0.5))
                    .cornerRadius(.Corner.regular)
                    .contentShape(.rect)
                    .tappable { vm.toggleClassification(classification: classification) }
                }
            }
        }
    }
}

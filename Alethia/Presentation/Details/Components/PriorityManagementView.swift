//
//  PriorityManagementView.swift
//  Alethia
//
//  Created by Angelo Carasig on 8/6/2025.
//

import SwiftUI
import Kingfisher

struct PriorityManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    
    @State private var editMode: Bool = false
    
    // Local copies for editing
    @State private var origins: [OriginExtended] = []
    @State private var scanlators: [ScanlatorExtended] = []
    
    // Original copies for comparison
    @State private var originalOrigins: [OriginExtended] = []
    @State private var originalScanlators: [ScanlatorExtended] = []
    
    private var hasChanges: Bool {
        // Compare origins by their order
        if origins.map(\.origin.id) != originalOrigins.map(\.origin.id) {
            return true
        }
        
        // Compare scanlators by their order within each origin
        let currentGrouped = Dictionary(grouping: scanlators) { $0.originId }
        let originalGrouped = Dictionary(grouping: originalScanlators) { $0.originId }
        
        for originId in currentGrouped.keys {
            let current = currentGrouped[originId] ?? []
            let original = originalGrouped[originId] ?? []
            
            if current.map(\.scanlator.id) != original.map(\.scanlator.id) {
                return true
            }
        }
        
        return false
    }
    
    var body: some View {
        List {
            // Display Settings Section
            Section(header: Text("Display Settings").textCase(.uppercase)) {
                Toggle("Show All Chapters", isOn: Binding(
                    get: { vm.details?.manga.showAllChapters ?? false },
                    set: { newValue in
                        // TODO: Update manga settings
                        vm.updateChapters()
                    }
                ))
                .tint(.green)
                
                Toggle("Show Half Chapters", isOn: Binding(
                    get: { vm.details?.manga.showHalfChapters ?? true },
                    set: { newValue in
                        // TODO: Update manga settings
                        vm.updateChapters()
                    }
                ))
                .tint(.green)
                .opacity((vm.details?.manga.showAllChapters ?? false) ? 0.5 : 1)
                .disabled(vm.details?.manga.showAllChapters ?? false)
            }
            .listStyle(.insetGrouped)
            
            // Source Priority Section
            Section(header: Text("Source Priority")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundStyle(.secondary)
            ) {
                VStack(spacing: Constants.Spacing.regular) {
                    ForEach(Array(origins.enumerated()), id: \.element.id) { index, origin in
                        OriginPriorityRow(
                            origin: origin,
                            index: index,
                            isEditing: editMode
                        )
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(Constants.Corner.Radius.regular)
                        .padding(.horizontal, Constants.Padding.screen)
                    }
                    .onMove(perform: editMode ? handleOriginMove : nil)
                    .moveDisabled(!editMode)
                }
                .padding(.top, Constants.Padding.regular)
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            
            // Scanlator Priority Section
            Section(header: Text("Scanlator Priority")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundStyle(.secondary)
            ) {
                VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                    ForEach(groupedScanlators(), id: \.origin.id) { group in
                        ScanlatorGroupSection(
                            group: group,
                            isEditing: editMode,
                            onMove: handleScanlatorMove
                        )
                    }
                }
                .padding(.top, Constants.Padding.regular)
            }
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .scrollIndicators(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
        .navigationTitle("Chapter Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(editMode ? "Done" : "Edit") {
                    withAnimation {
                        if editMode && hasChanges {
                            saveChanges()
                        }
                        editMode.toggle()
                    }
                }
            }
        }
        .onAppear {
            loadData()
        }
    }
}

// MARK: - Origin Priority Row
private struct OriginPriorityRow: View {
    let origin: OriginExtended
    let index: Int
    let isEditing: Bool
    
    var body: some View {
        HStack {
            KFImage(URL(fileURLWithPath: origin.sourceIcon))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: Constants.Icon.Size.regular, height: Constants.Icon.Size.regular)
                .cornerRadius(Constants.Corner.Radius.regular)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text(origin.sourceName)
                    .lineLimit(1)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(origin.sourceHost)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("(\(origin.chapterCount) Chapters)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .padding(.leading, Constants.Padding.regular)
            }
        }
        .padding(.vertical, Constants.Padding.regular)
        .padding(.horizontal, Constants.Padding.minimal)
        .padding(.bottom, Constants.Padding.minimal)
        .opacity(origin.source?.disabled ?? false ? 0.6 : 1.0)
    }
}

// MARK: - Scanlator Group Section
private struct ScanlatorGroupSection: View {
    let group: (origin: OriginExtended, scanlators: [ScanlatorExtended])
    let isEditing: Bool
    let onMove: (IndexSet, Int, Int64) -> Void
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Expandable header
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                VStack {
                    HStack(spacing: Constants.Spacing.regular) {
                        // Origin icon
                        KFImage(URL(fileURLWithPath: group.origin.sourceIcon))
                            .placeholder { Color.tint.shimmer() }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .cornerRadius(Constants.Corner.Radius.regular)
                        
                        // Origin info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.origin.sourceName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("\(group.scanlators.count) scanlator\(group.scanlators.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Chevron indicator
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    
                    if isExpanded {
                        Divider()
                    }
                }
                .padding(.horizontal, Constants.Padding.screen)
                .padding(.top, Constants.Padding.regular)
                .padding(.bottom, Constants.Padding.minimal)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(Constants.Corner.Radius.button)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Constants.Padding.screen)
            .padding(.bottom, isExpanded ? Constants.Spacing.regular : 0)
            
            // Scanlator list
            if isExpanded {
                List {
                    ForEach(group.scanlators, id: \.id) { scanlator in
                        let index = group.scanlators.firstIndex(where: { $0.id == scanlator.id }) ?? 0
                        ScanlatorPriorityRow(
                            scanlator: scanlator,
                            isEditing: isEditing,
                            index: index + 1,
                            total: group.scanlators.count
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                        .listRowSeparator(.hidden)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                    }
                    .onMove { source, destination in
                        onMove(source, destination, group.origin.origin.id!)
                    }
                    .moveDisabled(!isEditing)
                }
                .listStyle(.plain)
                .frame(height: CGFloat(group.scanlators.count) * 56) // Approximate height per row
                .padding(.horizontal, Constants.Padding.screen)
                .scrollDisabled(true)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: group.scanlators)
            }
        }
        .padding(.bottom, Constants.Padding.regular)
    }
}

// MARK: - Scanlator Priority Row
private struct ScanlatorPriorityRow: View {
    let scanlator: ScanlatorExtended
    let isEditing: Bool
    let index: Int
    let total: Int
    
    private var priorityColor: Color {
        switch index {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            // Priority indicator
            Circle()
                .fill(priorityColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(priorityColor)
                )
            
            // Scanlator name
            Text(scanlator.scanlator.name)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Drag handle in edit mode
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(.rect)
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, Constants.Padding.regular + Constants.Padding.minimal)
        .background(
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - Helper Methods
private extension PriorityManagementView {
    func groupedScanlators() -> [(origin: OriginExtended, scanlators: [ScanlatorExtended])] {
        let grouped = Dictionary(grouping: scanlators) { $0.originId }
        
        return origins.compactMap { origin in
            guard let originId = origin.origin.id,
                  let scanlatorsForOrigin = grouped[originId] else {
                return nil
            }
            
            let sortedScanlators = scanlatorsForOrigin.sorted { s1, s2 in
                let index1 = scanlators.firstIndex(where: { $0.id == s1.id }) ?? 0
                let index2 = scanlators.firstIndex(where: { $0.id == s2.id }) ?? 0
                return index1 < index2
            }
            
            return (origin: origin, scanlators: sortedScanlators)
        }
    }
}

// MARK: - Data Management
private extension PriorityManagementView {
    func loadData() {
        origins = vm.details?.origins ?? []
        scanlators = vm.details?.scanlators ?? []
        
        originalOrigins = origins
        originalScanlators = scanlators
    }
    
    func saveChanges() {
        // TODO: Implement actual save using modelContext
        // Update origin priorities
        // Update scanlator priorities
        
        // For now, just update the original state
        originalOrigins = origins
        originalScanlators = scanlators
    }
}

// MARK: - Actions
private extension PriorityManagementView {
    func handleOriginMove(from source: IndexSet, to destination: Int) {
        origins.move(fromOffsets: source, toOffset: destination)
    }
    
    func handleScanlatorMove(from source: IndexSet, to destination: Int, originId: Int64) {
        var indices: [Int] = []
        for (index, scanlator) in scanlators.enumerated() {
            if scanlator.originId == originId {
                indices.append(index)
            }
        }
        
        var scanlatorsForOrigin = indices.map { scanlators[$0] }
        scanlatorsForOrigin.move(fromOffsets: source, toOffset: destination)
        
        for (subIndex, mainIndex) in indices.enumerated() {
            scanlators[mainIndex] = scanlatorsForOrigin[subIndex]
        }
    }
}

// MARK: - ViewModel Extension
extension DetailsViewModel {
    func updateChapters() {
        // TODO: Implement chapter list update based on settings
        objectWillChange.send()
    }
}

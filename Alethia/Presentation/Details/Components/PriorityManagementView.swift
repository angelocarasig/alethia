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
    
    @State private var selectedTab: Tab = .origins
    @State private var editMode: EditMode = .inactive
    
    // Local copies for editing
    @State private var origins: [OriginExtended] = []
    @State private var scanlators: [ScanlatorExtended] = []
    
    // Original copies for comparison
    @State private var originalOrigins: [OriginExtended] = []
    @State private var originalScanlators: [ScanlatorExtended] = []
    
    @State private var showingDiscardAlert: Bool = false
    
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
    
    private enum Tab: String, CaseIterable {
        case origins = "Origins"
        case scanlators = "Scanlators"
        
        var icon: String {
            switch self {
            case .origins: return "network"
            case .scanlators: return "person.2.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                TabPicker()
                
                // Content
                TabView(selection: $selectedTab) {
                    OriginsListView()
                        .tag(Tab.origins)
                    
                    ScanlatorsListView()
                        .tag(Tab.scanlators)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
            .navigationTitle("Priority Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if editMode == .active {
                        Button("Save") {
                            handleSave()
                        }
                        .fontWeight(.semibold)
                        .disabled(!hasChanges)
                    } else {
                        Button("Edit") {
                            withAnimation {
                                editMode = .active
                            }
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .onAppear {
                loadData()
            }
            .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Do you want to discard them?")
            }
        }
    }
}

// MARK: - Tab Picker

private extension PriorityManagementView {
    @ViewBuilder
    func TabPicker() -> some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, Constants.Padding.regular)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Origins List

private extension PriorityManagementView {
    @ViewBuilder
    func OriginsListView() -> some View {
        List {
            Section {
                ForEach(Array(origins.enumerated()), id: \.element.id) { index, origin in
                    OriginRow(origin: origin, index: index)
                        .listRowInsets(EdgeInsets(
                            top: Constants.Padding.regular,
                            leading: Constants.Padding.screen,
                            bottom: Constants.Padding.regular,
                            trailing: Constants.Padding.screen
                        ))
                }
                .onMove(perform: editMode == .active ? handleOriginMove : nil)
                .onDelete(perform: editMode == .active ? handleOriginDelete : nil)
            } header: {
                if editMode == .active {
                    Text("Drag to reorder priority")
                        .textCase(.none)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Higher priority origins will be used first when loading chapters.")
                    .textCase(.none)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    func OriginRow(origin: OriginExtended, index: Int) -> some View {
        HStack(spacing: Constants.Spacing.large) {
            // Priority Badge
            PriorityBadge(priority: index)
            
            // Source Icon
            KFImage(URL(fileURLWithPath: origin.sourceIcon))
                .placeholder {
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                        .fill(Color.gray.opacity(0.3))
                        .shimmer()
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Constants.Icon.Size.regular, height: Constants.Icon.Size.regular)
                .cornerRadius(Constants.Corner.Radius.regular)
            
            // Origin Info
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text(origin.sourceName)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(origin.sourceHost)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: Constants.Spacing.minimal) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text("^[\(origin.chapterCount) chapter](inflect: true)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Status Indicators
            HStack(spacing: Constants.Spacing.regular) {
                if origin.source?.disabled ?? false {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if editMode == .inactive {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .opacity(origin.source?.disabled ?? false ? 0.6 : 1.0)
    }
}

// MARK: - Scanlators List

private extension PriorityManagementView {
    @ViewBuilder
    func ScanlatorsListView() -> some View {
        List {
            // Group scanlators by origin
            ForEach(groupedScanlators(), id: \.origin.id) { group in
                Section {
                    ForEach(Array(group.scanlators.enumerated()), id: \.element.id) { index, scanlator in
                        ScanlatorRow(scanlator: scanlator, index: index)
                            .listRowInsets(EdgeInsets(
                                top: Constants.Padding.regular,
                                leading: Constants.Padding.screen,
                                bottom: Constants.Padding.regular,
                                trailing: Constants.Padding.screen
                            ))
                    }
                    .onMove(perform: editMode == .active ? { source, destination in
                        handleScanlatorMove(from: source, to: destination, originId: group.origin.origin.id!)
                    } : nil)
                    .onDelete(perform: editMode == .active ? { indexSet in
                        handleScanlatorDelete(at: indexSet, originId: group.origin.origin.id!)
                    } : nil)
                } header: {
                    HStack(spacing: Constants.Spacing.regular) {
                        KFImage(URL(fileURLWithPath: group.origin.sourceIcon))
                            .placeholder {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .shimmer()
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        
                        Text(group.origin.sourceName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("^[\(group.scanlators.count) scanlator](inflect: true)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .textCase(.none)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    func ScanlatorRow(scanlator: ScanlatorExtended, index: Int) -> some View {
        HStack(spacing: Constants.Spacing.large) {
            // Priority Badge
            PriorityBadge(priority: index)
            
            // Scanlator Info
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text(scanlator.scanlator.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let chapterCount = getChapterCount(for: scanlator) {
                    HStack(spacing: Constants.Spacing.minimal) {
                        Image(systemName: "doc.text")
                            .font(.caption2)
                        Text("^[\(chapterCount) chapter](inflect: true)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Drag Handle
            if editMode == .inactive {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Shared Components

private extension PriorityManagementView {
    @ViewBuilder
    func PriorityBadge(priority: Int) -> some View {
        Text("\(priority + 1)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(priorityColor(for: priority))
            .clipShape(Circle())
    }
}

// MARK: - Helper Methods

private extension PriorityManagementView {
    func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 0: return .appGreen
        case 1: return .appBlue
        case 2: return .appOrange
        default: return .secondary
        }
    }
    
    func groupedScanlators() -> [(origin: OriginExtended, scanlators: [ScanlatorExtended])] {
        // Group scanlators by their origin ID
        let grouped = Dictionary(grouping: scanlators) { scanlator in
            scanlator.originId
        }
        
        // Map to origin-scanlator pairs, maintaining origin order
        return origins.compactMap { origin in
            guard let originId = origin.origin.id,
                  let scanlatorsForOrigin = grouped[originId] else {
                return nil
            }
            
            // Sort by current index to maintain display order
            let sortedScanlators = scanlatorsForOrigin.sorted { s1, s2 in
                let index1 = scanlators.firstIndex(where: { $0.id == s1.id }) ?? 0
                let index2 = scanlators.firstIndex(where: { $0.id == s2.id }) ?? 0
                return index1 < index2
            }
            
            return (origin: origin, scanlators: sortedScanlators)
        }
    }
    
    func getChapterCount(for scanlator: ScanlatorExtended) -> Int? {
        // TODO: Implement chapter count for scanlator within this origin
        // This would need to be added to the ScanlatorExtended query
        return nil
    }
}

// MARK: - Data Management

private extension PriorityManagementView {
    func loadData() {
        origins = vm.details?.origins ?? []
        scanlators = vm.details?.scanlators ?? []
        
        // Store original state for comparison
        originalOrigins = origins
        originalScanlators = scanlators
    }
}

// MARK: - Origin Actions

private extension PriorityManagementView {
    func handleOriginMove(from source: IndexSet, to destination: Int) {
        origins.move(fromOffsets: source, toOffset: destination)
    }
    
    func handleOriginDelete(at indexSet: IndexSet) {
        origins.remove(atOffsets: indexSet)
    }
}

// MARK: - Scanlator Actions

private extension PriorityManagementView {
    func handleScanlatorMove(from source: IndexSet, to destination: Int, originId: Int64) {
        // Find the indices of scanlators for this origin in the main array
        var indices: [Int] = []
        for (index, scanlator) in scanlators.enumerated() {
            if scanlator.originId == originId {
                indices.append(index)
            }
        }
        
        // Extract scanlators for this origin in order
        var scanlatorsForOrigin = indices.map { scanlators[$0] }
        
        // Move within the subset
        scanlatorsForOrigin.move(fromOffsets: source, toOffset: destination)
        
        // Replace them back in the main array
        for (subIndex, mainIndex) in indices.enumerated() {
            scanlators[mainIndex] = scanlatorsForOrigin[subIndex]
        }
    }
    
    func handleScanlatorDelete(at indexSet: IndexSet, originId: Int64) {
        // Get scanlators for this origin
        let scanlatorsForOrigin = scanlators.filter { $0.originId == originId }
        
        // Remove the selected scanlators
        for index in indexSet.reversed() {
            if index < scanlatorsForOrigin.count {
                let scanlatorToRemove = scanlatorsForOrigin[index]
                scanlators.removeAll { $0.id == scanlatorToRemove.id && $0.originId == originId }
            }
        }
    }
}

// MARK: - Navigation Actions

private extension PriorityManagementView {
    func handleCancel() {
        if hasChanges {
            showingDiscardAlert = true
        } else {
            dismiss()
        }
    }
    
    func handleSave() {
        // TODO: Implement save functionality
        // This should:
        // 1. Update origin priorities based on their order
        // 2. Update OriginScanlator priorities based on their order within each origin
        // 3. Call appropriate use cases to persist changes
        
        // For now, update the original state and switch to non-edit mode
        originalOrigins = origins
        originalScanlators = scanlators
        
        withAnimation {
            editMode = .inactive
        }
        
        // Eventually this should save to database and dismiss
        // dismiss()
    }
}

// MARK: - Extensions

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

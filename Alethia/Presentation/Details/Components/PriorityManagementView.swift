//
//  PriorityManagementView.swift
//  Alethia
//
//  Created by Angelo Carasig on 8/6/2025.
//

import Core
import SwiftUI
import Kingfisher

struct PriorityManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    
    @State private var editMode: Bool = false
    
    @State private var originGroups: [OriginGroup] = []
    @State private var originalOriginGroups: [OriginGroup] = []
    
    struct OriginGroup: Identifiable {
        let id: Int64
        let origin: OriginExtended
        var scanlators: [ScanlatorExtended]
        
        init(origin: OriginExtended, scanlators: [ScanlatorExtended]) {
            self.id = origin.origin.id!
            self.origin = origin
            self.scanlators = scanlators
        }
    }
    
    private var hasChanges: Bool {
        guard originGroups.count == originalOriginGroups.count else { return true }
        
        for (index, group) in originGroups.enumerated() {
            let originalGroup = originalOriginGroups[index]
            
            if group.id != originalGroup.id { return true }
            
            if group.scanlators.count != originalGroup.scanlators.count { return true }
            
            for (scanlatorIndex, scanlator) in group.scanlators.enumerated() {
                let originalScanlator = originalGroup.scanlators[scanlatorIndex]
                if scanlator.id != originalScanlator.id { return true }
            }
        }
        
        return false
    }
    
    var body: some View {
        List {
            Section(header: Text("Display Settings").textCase(.uppercase)) {
                Toggle("Show All Chapters", isOn: Binding(
                    get: { vm.details?.manga.showAllChapters ?? false },
                    set: { newValue in
                        vm.updateMangaSettings(showAllChapters: newValue)
                    }
                ))
                .tint(.green)
                
                Toggle("Show Half Chapters", isOn: Binding(
                    get: { vm.details?.manga.showHalfChapters ?? true },
                    set: { newValue in
                        vm.updateMangaSettings(showHalfChapters: newValue)
                    }
                ))
                .tint(.green)
                .opacity((vm.details?.manga.showAllChapters ?? false) ? 0.5 : 1)
                .disabled(vm.details?.manga.showAllChapters ?? false)
            }
            .listStyle(.insetGrouped)
            
            Section(header: Text("Source Priority")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundStyle(.secondary)
            ) {
                ForEach(Array(originGroups.enumerated()), id: \.element.id) { index, group in
                    OriginPriorityRow(
                        origin: group.origin,
                        index: index,
                        isEditing: editMode
                    )
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(.Corner.regular)
                    .padding(.horizontal, .Padding.screen)
                    .padding(.vertical, .Padding.minimal)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                .onMove(perform: editMode ? handleOriginMove : nil)
            }
            
            Section(header: Text("Scanlator Priority")
                .textCase(.uppercase)
                .font(.caption)
                .foregroundStyle(.secondary)
            ) {
                VStack(alignment: .leading, spacing: .Spacing.regular) {
                    ForEach(Array(originGroups.enumerated()), id: \.element.id) { groupIndex, group in
                        ScanlatorGroupSection(
                            group: group,
                            groupIndex: groupIndex,
                            isEditing: editMode,
                            onMove: handleScanlatorMove
                        )
                    }
                }
                .padding(.top, .Padding.regular)
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

private struct ScanlatorGroupSection: View {
    let group: PriorityManagementView.OriginGroup
    let groupIndex: Int
    let isEditing: Bool
    let onMove: (IndexSet, Int, Int) -> Void
    @State private var isExpanded: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                VStack {
                    HStack(spacing: .Spacing.regular) {
                        KFImage(URL(fileURLWithPath: group.origin.sourceIcon))
                            .placeholder { Color.tint.shimmer() }
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .cornerRadius(.Corner.regular)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.origin.sourceName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Text("\(group.scanlators.count) scanlator\(group.scanlators.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
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
                .padding(.horizontal, .Padding.screen)
                .padding(.top, .Padding.regular)
                .padding(.bottom, .Padding.minimal)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(.Corner.button)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, .Padding.screen)
            .padding(.bottom, isExpanded ? .Spacing.regular : 0)
            
            if isExpanded {
                List {
                    ForEach(Array(group.scanlators.enumerated()), id: \.element.id) { index, scanlator in
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
                        onMove(source, destination, groupIndex)
                    }
                    .moveDisabled(!isEditing)
                }
                .listStyle(.plain)
                .frame(height: CGFloat(group.scanlators.count) * 56)
                .padding(.horizontal, .Padding.screen)
                .scrollDisabled(true)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: group.scanlators)
            }
        }
        .padding(.bottom, .Padding.regular)
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
                .frame(width: .Icon.regular.width, height: .Icon.regular.height)
                .cornerRadius(.Corner.regular)
            
            VStack(alignment: .leading, spacing: .Spacing.minimal) {
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
                    .padding(.leading, .Padding.regular)
            }
        }
        .padding(.vertical, .Padding.regular)
        .padding(.horizontal, .Padding.minimal)
        .padding(.bottom, .Padding.minimal)
        .opacity(origin.source?.disabled ?? false ? 0.6 : 1.0)
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
        HStack(spacing: .Spacing.regular) {
            Circle()
                .fill(priorityColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(index)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(priorityColor)
                )
            
            Text(scanlator.scanlator.name)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isEditing {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(.rect)
            }
        }
        .padding(.horizontal, .Padding.screen)
        .padding(.vertical, .Padding.regular + .Padding.minimal)
        .background(
            RoundedRectangle(cornerRadius: .Corner.regular)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
}

private extension PriorityManagementView {
    func loadData() {
        guard let details = vm.details else { return }
        
        let origins = details.origins.sorted { $0.origin.priority < $1.origin.priority }
        let scanlators = details.scanlators
        
        let scanlatorsByOrigin = Dictionary(grouping: scanlators) { $0.originId }
        
        originGroups = origins.compactMap { origin in
            guard let originId = origin.origin.id,
                  let scanlatorsForOrigin = scanlatorsByOrigin[originId] else {
                return nil
            }
            
            let sortedScanlators = scanlatorsForOrigin.sorted { $0.priority < $1.priority }
            
            return OriginGroup(origin: origin, scanlators: sortedScanlators)
        }
        
        originalOriginGroups = originGroups.map { group in
            OriginGroup(origin: group.origin, scanlators: group.scanlators)
        }
    }
    
    func saveChanges() {
        print("💾 Saving changes:")
        
        let originalOriginOrder = originalOriginGroups.map { $0.origin.origin.id! }
        let currentOriginOrder = originGroups.map { $0.origin.origin.id! }
        
        if originalOriginOrder != currentOriginOrder {
            print("  📋 Origin order changed")
            let reorderedOrigins = originGroups.map { $0.origin }
            vm.updateOriginPriorities(reorderedOrigins)
        }
        
        for (index, group) in originGroups.enumerated() {
            let originalGroup = originalOriginGroups[index]
            let originalScanlatorOrder = originalGroup.scanlators.map { $0.scanlator.id! }
            let currentScanlatorOrder = group.scanlators.map { $0.scanlator.id! }
            
            if originalScanlatorOrder != currentScanlatorOrder {
                print("  🔄 Scanlator order changed for origin: \(group.origin.sourceName)")
                vm.updateScanlatorPriorities(group.scanlators, for: group.origin.origin.id!)
            }
        }
        
        originalOriginGroups = originGroups.map { group in
            OriginGroup(origin: group.origin, scanlators: group.scanlators)
        }
        
        print("💾 Save completed!")
    }
    
    func handleOriginMove(from source: IndexSet, to destination: Int) {
        originGroups.move(fromOffsets: source, toOffset: destination)
    }
    
    func handleScanlatorMove(from source: IndexSet, to destination: Int, groupIndex: Int) {
        guard groupIndex < originGroups.count else { return }
        
        print("🔄 Moving scanlator in group \(groupIndex)")
        print("   From: \(source) To: \(destination)")
        print("   Before: \(originGroups[groupIndex].scanlators.map { $0.scanlator.name })")
        
        originGroups[groupIndex].scanlators.move(fromOffsets: source, toOffset: destination)
        
        print("   After: \(originGroups[groupIndex].scanlators.map { $0.scanlator.name })")
    }
}

//
//  ManageCollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import SwiftUI

struct ManageCollectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    
    @State private var selectedCollections: Set<Int64> = []
    @State private var searchText: String = ""
    @State private var hasChanges: Bool = false
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showCreateSheet: Bool = false
    
    // MARK: - Computed Properties
    private var currentCollections: Set<Int64> {
        Set(vm.details?.collections.compactMap(\.collection.id) ?? [])
    }
    
    private var filteredCollections: [CollectionExtended] {
        guard !searchText.isEmpty else { return vm.collections }
        return vm.collections.filter {
            $0.collection.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var changeCount: Int {
        abs(selectedCollections.count - currentCollections.count)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        SearchBar(searchText: $searchText)
                        CollectionsSection()
                    }
                    .padding(.top, 24)
                    .padding(.bottom, hasChanges ? 100 : 24)
                    .padding(.horizontal, Constants.Padding.screen)
                }
                
                if hasChanges {
                    BottomActionBar()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Manage Collections")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar { toolbarContent }
            .onAppear { selectedCollections = currentCollections }
            .onChange(of: selectedCollections) { updateChangeState() }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCreateSheet) {
                NewCollectionView { name, color, icon in
                    do {
                        try vm.addCollection(name: name, color: color, icon: icon)
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
            }
        }
    }
}

// MARK: - View Components
private extension ManageCollectionsView {
    @ViewBuilder
    func CollectionsSection() -> some View {
        if vm.collections.isEmpty {
            EmptyStateView(showCreateSheet: $showCreateSheet)
        } else if filteredCollections.isEmpty && !searchText.isEmpty {
            NoResultsView()
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filteredCollections, id: \.collection.id) { collection in
                    if let id = collection.collection.id {
                        CollectionRow(
                            collection: collection,
                            isSelected: selectedCollections.contains(id),
                            isInCurrentCollections: currentCollections.contains(id),
                            hasChanges: hasChanges,
                            onToggle: { toggleCollection(id) }
                        )
                    }
                }
            }
            .cornerRadius(Constants.Corner.Radius.panel)
        }
    }
    
    @ViewBuilder
    func BottomActionBar() -> some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: Constants.Spacing.toolbar) {
                ChangeIndicator(count: changeCount)
                
                Spacer()
                
                Button("Discard") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedCollections = currentCollections
                    }
                }
                .foregroundStyle(.red)
                
                Button(action: saveChanges) {
                    Group {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(width: 60, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding(.horizontal, Constants.Padding.screen + Constants.Padding.minimal)
            .padding(.vertical, Constants.Padding.regular)
            .background(.regularMaterial)
        }
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCreateSheet = true
            }
            label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Actions
private extension ManageCollectionsView {
    func updateChangeState() {
        withAnimation(.easeInOut(duration: 0.15)) {
            hasChanges = selectedCollections != currentCollections
        }
    }
    
    func toggleCollection(_ id: Int64) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedCollections.formSymmetricDifference([id])
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func saveChanges() {
        guard hasChanges else { return }
        
        isSaving = true
        
        do {
            try vm.updateMangaCollections(Array(selectedCollections))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSaving = false
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Collection Row
private struct CollectionRow: View {
    let collection: CollectionExtended
    let isSelected: Bool
    let isInCurrentCollections: Bool
    let hasChanges: Bool
    let onToggle: () -> Void
    
    private var color: Color {
        Color(hex: collection.collection.color)
    }
    
    private var isPendingAdd: Bool {
        !isInCurrentCollections && isSelected
    }
    
    private var isPendingRemove: Bool {
        isInCurrentCollections && !isSelected && hasChanges
    }
    
    private var statusIcon: (name: String, color: Color)? {
        if isPendingAdd {
            return ("checkmark.circle.fill", .green)
        } else if isPendingRemove {
            return ("xmark.circle.fill", .red)
        } else if isInCurrentCollections && isSelected {
            return ("checkmark.circle.fill", .green)
        }
        return nil
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Constants.Spacing.toolbar) {
                // Icon
                CollectionIcon(
                    icon: collection.collection.icon,
                    color: color
                )
                
                // Content
                VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                    HStack(spacing: Constants.Spacing.regular / 2) {
                        Text(collection.collection.name)
                            .lineLimit(1)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        if let (iconName, iconColor) = statusIcon {
                            PulsingIcon(
                                systemName: iconName,
                                color: iconColor,
                                isPulsing: isPendingAdd || isPendingRemove
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: statusIcon?.name)
                    
                    Text("^[\(collection.itemCount) item](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .padding(.horizontal, Constants.Padding.screen + Constants.Padding.minimal)
            .padding(.vertical, Constants.Padding.regular)
            .background(Color.tint.opacity(0.50))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Collection Icon
private struct CollectionIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                .fill(color.opacity(0.2))
                .frame(width: 56, height: 56)
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Pulsing Icon
private struct PulsingIcon: View {
    let systemName: String
    let color: Color
    let isPulsing: Bool
    
    @State private var animationPhase = false
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 16))
            .foregroundStyle(color)
            .opacity(isPulsing ? (animationPhase ? 0.3 : 1.0) : 1.0)
            .onAppear {
                if isPulsing {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        animationPhase = true
                    }
                }
            }
            .onChange(of: isPulsing) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        animationPhase = true
                    }
                } else {
                    withAnimation(.default) {
                        animationPhase = false
                    }
                }
            }
    }
}

// MARK: - Change Indicator
private struct ChangeIndicator: View {
    let count: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: Constants.Spacing.regular) {
            ZStack {
                // Background circle with pulsing glow
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(.orange.opacity(isPulsing ? 0.6 : 0.3), lineWidth: 2)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .opacity(isPulsing ? 0 : 1)
                    )
                
                // Count badge
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(.orange)
                            .shadow(color: .orange.opacity(0.3), radius: Constants.Spacing.minimal, x: 0, y: 2)
                    )
            }
            
            Text("Unsaved Changes")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, Constants.Padding.regular + Constants.Padding.minimal)
        .padding(.vertical, Constants.Padding.regular / 2)
        .background(
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.panel)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.panel)
                        .stroke(.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Empty States
private struct EmptyStateView: View {
    @Binding var showCreateSheet: Bool
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large + Constants.Spacing.regular) {
            Image(systemName: "plus.rectangle.on.folder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: Constants.Spacing.regular) {
                Text("No collections yet")
                    .font(.headline)
                
                Text("Create your first collection to organize your library")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Collection") {
                showCreateSheet = true
            }
            .fontWeight(.medium)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, Constants.Icon.Size.regular)
    }
}

private struct NoResultsView: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.toolbar) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("No results found")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

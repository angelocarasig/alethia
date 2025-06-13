//
//  ManageCollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Core
import SwiftUI

struct ManageCollectionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    
    // MARK: - State Properties
    @State private var selectedCollections: Set<Int64> = []
    @State private var searchText: String = ""
    @State private var hasChanges: Bool = false
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showCreateSheet: Bool = false
    @State private var collectionToDelete: Collection? = nil
    @State private var showDeleteConfirmation: Bool = false
    
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
        // Filter out any selected collections that no longer exist in vm.collections
        let existingCollectionIds = Set(vm.collections.compactMap(\.collection.id))
        let validSelectedCollections = selectedCollections.intersection(existingCollectionIds)
        let validCurrentCollections = currentCollections.intersection(existingCollectionIds)
        
        // Calculate the symmetric difference between valid collections
        let changes = validSelectedCollections.symmetricDifference(validCurrentCollections)
        return changes.count
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainContent
                bottomActionBar
            }
            .navigationTitle("Manage Collections")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar { toolbarContent }
            .onAppear { setupInitialState() }
            .onChange(of: selectedCollections) { updateChangeState() }
            .alert("Error", isPresented: $showError) { errorAlert }
            .confirmationDialog(
                "Delete Collection",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible,
                presenting: collectionToDelete
            ) { collection in
                deleteConfirmationActions(for: collection)
            } message: { collection in
                Text("Are you sure you want to delete \"\(collection.name)\"? This action cannot be undone.")
            }
            .sheet(isPresented: $showCreateSheet) { createCollectionSheet }
        }
    }
}

// MARK: - Main Content
private extension ManageCollectionsView {
    @ViewBuilder
    var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                searchBar
                collectionsSection
            }
            .padding(.top, 24)
            .padding(.bottom, hasChanges ? 100 : 24)
            .padding(.horizontal, .Padding.screen)
        }
    }
    
    @ViewBuilder
    var searchBar: some View {
        SearchBar(searchText: $searchText)
    }
    
    @ViewBuilder
    var collectionsSection: some View {
        if vm.collections.isEmpty {
            emptyCollectionsView
        } else if filteredCollections.isEmpty && !searchText.isEmpty {
            noSearchResultsView
        } else {
            collectionsList
        }
    }
    
    @ViewBuilder
    var collectionsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredCollections, id: \.collection.id) { collectionExtended in
                if let id = collectionExtended.collection.id {
                    CollectionRow(
                        collection: collectionExtended,
                        isSelected: selectedCollections.contains(id),
                        isInCurrentCollections: currentCollections.contains(id),
                        hasChanges: hasChanges,
                        onToggle: { toggleCollection(id) },
                        onDelete: {
                            collectionToDelete = collectionExtended.collection
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
        }
        .cornerRadius(.Corner.panel)
    }
}

// MARK: - Content Unavailable Views
private extension ManageCollectionsView {
    @ViewBuilder
    var emptyCollectionsView: some View {
        ContentUnavailableView {
            Label("No Collections", systemImage: "folder")
        } description: {
            Text("Create your first collection to organize your library")
        } actions: {
            Button("Create Collection") {
                showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 60)
    }
    
    @ViewBuilder
    var noSearchResultsView: some View {
        ContentUnavailableView.search(text: searchText)
            .padding(.vertical, 60)
    }
}

// MARK: - Bottom Action Bar
private extension ManageCollectionsView {
    @ViewBuilder
    var bottomActionBar: some View {
        if hasChanges {
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: .Spacing.toolbar) {
                    ChangeIndicator(count: changeCount)
                    
                    Spacer()
                    
                    discardButton
                    saveButton
                }
                .padding(.horizontal, .Padding.screen + .Padding.minimal)
                .padding(.vertical, .Padding.regular)
                .background(.regularMaterial)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    var discardButton: some View {
        Button("Discard") {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCollections = currentCollections
            }
        }
        .foregroundStyle(.red)
    }
    
    @ViewBuilder
    var saveButton: some View {
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
}

// MARK: - Toolbar
private extension ManageCollectionsView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCreateSheet = true
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.medium)
            }
        }
    }
}

// MARK: - Alerts & Dialogs
private extension ManageCollectionsView {
    @ViewBuilder
    var errorAlert: some View {
        Button("OK", role: .cancel) { }
    }
    
    @ViewBuilder
    func deleteConfirmationActions(for collection: Collection) -> some View {
        Button("Delete", role: .destructive) {
            deleteCollection(collection)
        }
        Button("Cancel", role: .cancel) {
            collectionToDelete = nil
        }
    }
}

// MARK: - Sheets
private extension ManageCollectionsView {
    @ViewBuilder
    var createCollectionSheet: some View {
        CollectionFormView(mode: .create) { name, color, icon in
            do {
                try vm.addCollection(name: name, color: color, icon: icon)
                return .success(())
            } catch {
                return .failure(error)
            }
        }
    }
}

// MARK: - Actions
private extension ManageCollectionsView {
    func setupInitialState() {
        selectedCollections = currentCollections
    }
    
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
    
    func deleteCollection(_ collection: Collection) {
        guard let id = collection.id else { return }
        
        do {
            try vm.deleteCollection(collectionId: id)
            selectedCollections.remove(id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = "Failed to delete collection: \(error.localizedDescription)"
            showError = true
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        
        collectionToDelete = nil
    }
}

// MARK: - Collection Row
private struct CollectionRow: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    let collection: CollectionExtended
    let isSelected: Bool
    let isInCurrentCollections: Bool
    let hasChanges: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    // MARK: - Computed Properties
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
    
    // MARK: - Body
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: .Spacing.toolbar) {
                selectionIndicator
                collectionIcon
                collectionContent
                Spacer()
                menuButton
            }
            .padding(.horizontal, .Padding.screen + .Padding.minimal)
            .padding(.vertical, .Padding.regular)
            .background(Color.tint.opacity(0.50))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Components
    @ViewBuilder
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 24))
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    @ViewBuilder
    private var collectionIcon: some View {
        CollectionIcon(
            icon: collection.collection.icon,
            color: color
        )
    }
    
    @ViewBuilder
    private var collectionContent: some View {
        VStack(alignment: .leading, spacing: .Spacing.minimal) {
            HStack(spacing: .Spacing.regular / 2) {
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
    }
    
    @ViewBuilder
    private var menuButton: some View {
        Menu {
            NavigationLink {
                CollectionFormView(mode: .edit(collection.collection)) { name, color, icon in
                    do {
                        guard let collectionId = collection.collection.id else {
                            throw CollectionError.notFound(collection.collection.id)
                        }
                        
                        try vm.updateCollection(collectionId: collectionId, newName: name, newIcon: icon, newColor: color)
                        
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
            } label: {
                Label("Edit Collection", systemImage: "pencil")
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete Collection", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
    }
}

// MARK: - Supporting Components
private struct CollectionIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .Corner.button)
                .fill(color.opacity(0.2))
                .frame(width: 56, height: 56)
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
        }
    }
}

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
            .onAppear { startAnimation() }
            .onChange(of: isPulsing) { _, newValue in
                updateAnimation(newValue)
            }
    }
    
    private func startAnimation() {
        if isPulsing {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                animationPhase = true
            }
        }
    }
    
    private func updateAnimation(_ shouldPulse: Bool) {
        if shouldPulse {
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

private struct ChangeIndicator: View {
    @State private var isPulsing = false
    
    let count: Int
    
    var body: some View {
        HStack(spacing: .Spacing.regular) {
            pulsingBadge
            changeText
        }
        .padding(.horizontal, .Padding.regular + .Padding.minimal)
        .padding(.vertical, .Padding.regular / 2)
        .background(indicatorBackground)
        .onAppear { startPulsing() }
    }
    
    @ViewBuilder
    private var pulsingBadge: some View {
        ZStack {
            Circle()
                .fill(.orange.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(pulsingOverlay)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(.orange)
                        .shadow(color: .orange.opacity(0.3), radius: .Spacing.minimal, x: 0, y: 2)
                )
        }
    }
    
    @ViewBuilder
    private var pulsingOverlay: some View {
        Circle()
            .stroke(.orange.opacity(isPulsing ? 0.6 : 0.3), lineWidth: 2)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0 : 1)
    }
    
    @ViewBuilder
    private var changeText: some View {
        Text(count == 1 ? "Unsaved Change" : "Unsaved Changes")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }
    
    @ViewBuilder
    private var indicatorBackground: some View {
        RoundedRectangle(cornerRadius: .Corner.panel)
            .fill(.orange.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: .Corner.panel)
                    .stroke(.orange.opacity(0.2), lineWidth: 1)
            )
    }
    
    private func startPulsing() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
            isPulsing = true
        }
    }
}

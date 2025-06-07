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
    
    private var allCollections: [CollectionExtended] {
        vm.collections
    }
    
    private var currentCollections: Set<Int64> {
        Set(vm.details?.collections.compactMap { $0.collection.id } ?? [])
    }
    
    private var filteredCollections: [CollectionExtended] {
        if searchText.isEmpty {
            return allCollections
        }
        return allCollections.filter { collection in
            collection.collection.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info Banner
                InfoBanner()
                
                // Search Section
                SearchSection()
                
                // Collections List
                CollectionsList()
                
                // Action Footer
                ActionFooter()
            }
            .navigationTitle("Manage Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    SaveButton()
                }
            }
            .onAppear {
                // Initialize with current collections
                selectedCollections = currentCollections
            }
            .onChange(of: selectedCollections) { _, _ in
                hasChanges = selectedCollections != currentCollections
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Info Banner
    @ViewBuilder
    private func InfoBanner() -> some View {
        HStack(spacing: Constants.Spacing.regular) {
            // Left side - Info
            HStack(spacing: Constants.Spacing.regular) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                
                Text("Select collections for this manga")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side - Status
            if hasChanges {
                HStack(spacing: Constants.Spacing.minimal) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    
                    Text("Modified")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, Constants.Padding.regular)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
                .transition(.scale.combined(with: .opacity))
            } else if !selectedCollections.isEmpty {
                HStack(spacing: Constants.Spacing.minimal) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                    
                    Text("\(selectedCollections.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, Constants.Padding.regular)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, Constants.Padding.regular)
        .background(Color(UIColor.secondarySystemBackground))
        .animation(.spring(response: 0.3), value: hasChanges)
        .animation(.spring(response: 0.3), value: selectedCollections.count)
    }
    
    // MARK: - Search Section
    @ViewBuilder
    private func SearchSection() -> some View {
        VStack(spacing: Constants.Spacing.regular) {
            SearchBar(
                searchText: $searchText,
                placeholder: "Search collections..."
            )
            .padding(.horizontal, Constants.Padding.screen)
            
            if !searchText.isEmpty && filteredCollections.isEmpty {
                SearchEmptyState()
            }
        }
        .padding(.top, Constants.Padding.regular)
    }
    
    @ViewBuilder
    private func SearchEmptyState() -> some View {
        VStack(spacing: Constants.Spacing.regular) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text("No collections found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Try a different search term")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Constants.Padding.screen)
    }
    
    // MARK: - Collections List
    @ViewBuilder
    private func CollectionsList() -> some View {
        ScrollView {
            LazyVStack(spacing: Constants.Spacing.large) {
                if allCollections.isEmpty {
                    EmptyCollectionsState()
                } else {
                    ForEach(filteredCollections, id: \.id) { collection in
                        CollectionCard(collection: collection)
                    }
                }
            }
            .padding(.horizontal, Constants.Padding.screen)
            .padding(.top, Constants.Padding.regular)
        }
    }
    
    @ViewBuilder
    private func EmptyCollectionsState() -> some View {
        VStack(spacing: Constants.Spacing.large) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolEffect(.bounce, options: .repeating.speed(0.5))
            
            VStack(spacing: Constants.Spacing.regular) {
                Text("No Collections Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first collection to organize your manga library")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            NavigationLink(destination: NewCollectionView { name, color, icon in
                do {
                    try vm.addCollection(name: name, color: color, icon: icon)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }) {
                Label("Create Collection", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, Constants.Padding.screen * 2)
    }
    
    // MARK: - Collection Card
    private func CollectionCard(collection: CollectionExtended) -> some View {
        guard let collectionId = collection.collection.id else { return AnyView(EmptyView()) }
        
        let isSelected = selectedCollections.contains(collectionId)
        
        return AnyView(
            Button {
                toggleCollection(collectionId)
            } label: {
                HStack {
                    CollectionRowView(
                        collection: collection,
                        isSelected: isSelected,
                        showSelected: true
                    )
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        )
    }
    
    // MARK: - Action Footer
    @ViewBuilder
    private func ActionFooter() -> some View {
        VStack(spacing: Constants.Spacing.large) {
            // Quick Actions
            if !allCollections.isEmpty {
                HStack(spacing: Constants.Spacing.large) {
                    Button {
                        withAnimation {
                            selectedCollections.removeAll()
                        }
                    } label: {
                        Text("Clear All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .disabled(selectedCollections.isEmpty || isSaving)
                    
                    Divider()
                        .frame(height: 20)
                    
                    Button {
                        withAnimation {
                            selectedCollections = currentCollections
                        }
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .disabled(!hasChanges || isSaving)
                }
                .padding(.top, Constants.Padding.regular)
            }
            
            // Create New Collection Button
            NavigationLink(destination: NewCollectionView { name, color, icon in
                do {
                    try vm.addCollection(name: name, color: color, icon: icon)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }) {
                HStack(spacing: Constants.Spacing.regular) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Create New Collection")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                        .fill(.tint.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.bottom, Constants.Padding.screen)
    }
    
    @ViewBuilder
    private func SaveButton() -> some View {
        if isSaving {
            ProgressView()
                .scaleEffect(0.8)
        } else {
            Button("Save") {
                saveChanges()
            }
            .fontWeight(.semibold)
            .disabled(!hasChanges)
            .foregroundStyle(hasChanges ? Color.accentColor : Color.secondary)
        }
    }
    
    // MARK: - Helper Methods
    private func toggleCollection(_ id: Int64) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCollections.contains(id) {
                selectedCollections.remove(id)
            } else {
                selectedCollections.insert(id)
            }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func saveChanges() {
        guard hasChanges else { return }
        
        isSaving = true
        
        do {
            try vm.updateMangaCollections(Array(selectedCollections))
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSaving = false
        }
    }
}

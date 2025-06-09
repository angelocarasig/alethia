//
//  AddToLibrarySheet.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import SwiftUI

struct AddToLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    
    @State private var selectedCollections: Set<Int64> = []
    @State private var searchText: String = ""
    
    private var collections: [CollectionExtended] {
        vm.collections
    }
    
    private var filteredCollections: [CollectionExtended] {
        if searchText.isEmpty {
            return collections
        }
        return collections.filter { collection in
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
                
                // Collections Grid
                CollectionsSection()
                
                // Action Footer
                ActionFooter()
            }
            .navigationTitle("Add To Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    SaveButton()
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Info Banner
    @ViewBuilder
    private func InfoBanner() -> some View {
        HStack(spacing: Constants.Spacing.regular) {
            // Left side - Info icon and text
            HStack(spacing: Constants.Spacing.regular) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.blue)
                
                Text("Select collections to organize your manga")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Right side - Selection count
            if !selectedCollections.isEmpty {
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
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, Constants.Padding.regular)
        .background(Color.tint.opacity(0.25))
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
            
            Text("Try a different search term or create a new collection")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, Constants.Padding.screen)
    }
    
    // MARK: - Collections Section
    @ViewBuilder
    private func CollectionsSection() -> some View {
        ScrollView {
            LazyVStack(spacing: Constants.Spacing.large) {
                if filteredCollections.isEmpty && searchText.isEmpty {
                    EmptyCollectionsState()
                } else {
                    ForEach(filteredCollections, id: \.id) { collection in
                        CollectionCard(collection: collection)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    }
                }
            }
            .padding(.horizontal, Constants.Padding.screen)
            .padding(.top, Constants.Padding.regular)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: filteredCollections.count)
        }
        .scrollBounceBehavior(.basedOnSize)
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
        }
        .padding(.vertical, Constants.Padding.screen * 2)
    }
    
    private func CollectionCard(collection: CollectionExtended) -> some View {
        guard let collectionId = collection.collection.id else { return AnyView(EmptyView()) }
        
        let isSelected = selectedCollections.contains(collectionId)
        
        return AnyView(
            CollectionRowView(
                collection: collection,
                isSelected: isSelected
            )
            .tappable {
                toggleCollection(collectionId)
            }
        )
    }
    
    @ViewBuilder
    private func SelectionIndicator(isSelected: Bool, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(isSelected ? color : Color.secondary.opacity(0.3), lineWidth: 2)
                .frame(width: 22, height: 22) // Slightly smaller
                .background(
                    Circle()
                        .fill(isSelected ? color : Color.clear)
                        .frame(width: 22, height: 22)
                )
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    @ViewBuilder
    private func CollectionIconView(icon: String, color: Color, isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(isSelected ? 0.2 : 0.1))
                .frame(width: 40, height: 40) // Reduced from 50
                .overlay(
                    Circle()
                        .stroke(color.opacity(isSelected ? 0.4 : 0.2), lineWidth: 1)
                )
            
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium)) // Reduced from 22
                .foregroundStyle(color)
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    @ViewBuilder
    private func CollectionInfoView(collection: CollectionExtended) -> some View {
        VStack(alignment: .leading, spacing: 2) { // Reduced spacing
            Text(collection.collection.name)
                .font(.subheadline) // Changed from headline
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            HStack(spacing: Constants.Spacing.minimal) {
                Image(systemName: "book.closed")
                    .font(.caption2) // Smaller icon
                    .foregroundStyle(.secondary)
                
                Text("\(collection.itemCount) \(collection.itemCount == 1 ? "item" : "items")")
                    .font(.caption) // Changed from subheadline
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func CardBackground(isSelected: Bool, color: Color) -> some View {
        RoundedRectangle(cornerRadius: Constants.Corner.Radius.panel)
            .fill(
                isSelected ?
                LinearGradient(
                    colors: [color.opacity(0.1), color.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                    LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.panel)
                    .stroke(
                        isSelected ? color.opacity(0.4) : Color.secondary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
    }
    
    // MARK: - Action Footer
    @ViewBuilder
    private func ActionFooter() -> some View {
        VStack(spacing: Constants.Spacing.large) {
            // Create New Collection Button
            NavigationLink(destination: NewCollectionView { name, color, icon in
                do {
                    try vm.addCollection(name: name, color: color, icon: icon)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }) {
                Label("Create New Collection", systemImage: "plus")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.Corner.Radius.button))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.bottom, Constants.Padding.screen)
    }
    
    @ViewBuilder
    private func SaveButton() -> some View {
        Button("Save") {
            vm.addToLibrary(collections: Array(selectedCollections), onSuccess: {
                dismiss()
            })
        }
        .fontWeight(.semibold)
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
}

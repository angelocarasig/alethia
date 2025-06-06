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
    
    private var collections: [CollectionExtended] {
        vm.collections
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: Constants.Spacing.regular) {
                        if collections.isEmpty {
                            ContentUnavailableView {
                                Label("No Collections", systemImage: "folder.badge.plus")
                            } description: {
                                Text("Create your first collection?")
                            }
                        }
                        
                        ForEach(collections, id: \.id) { collection in
                            CollectionRow(collection: collection)
                        }
                    }
                }
                
                Divider()
                
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
            }
            .padding(.horizontal, Constants.Padding.screen)
            .navigationTitle("Add To Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        vm.addToLibrary(collections: Array(selectedCollections), onSuccess: {
                            dismiss()
                        })
                    }
                    .fontWeight(.semibold)
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func toggleCollection(_ id: Int64) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectedCollections.contains(id) {
                selectedCollections.remove(id)
            } else {
                selectedCollections.insert(id)
            }
        }
    }
    
    private func CollectionRow(collection: CollectionExtended) -> some View {
        guard let collectionId = collection.collection.id else { return AnyView(EmptyView()) }
        
        let isSelected = selectedCollections.contains(collectionId)
        let collectionIcon = collection.collection.icon
        let collectionColor = Color(hex: collection.collection.color)
        
        return AnyView(
            HStack(spacing: Constants.Spacing.large) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                        .stroke(isSelected ? collectionColor : Color.secondary.opacity(0.5), lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                .fill(isSelected ? collectionColor : Color.clear)
                        )
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .scaleEffect(isSelected ? 1 : 0)
                        .opacity(isSelected ? 1 : 0)
                }
                
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(collectionColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: collectionIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(collectionColor)
                }
                
                VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                    Text(collection.collection.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(collection.itemCount) \(collection.itemCount == 1 ? "item" : "items")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Constants.Padding.screen)
            .frame(height: 69)
            .background(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.panel)
                    .fill(isSelected ? collectionColor.opacity(0.08) : Color.clear)
                    .stroke(
                        isSelected ? collectionColor.opacity(0.3) : Color.secondary.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .contentShape(.rect)
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            .onTapGesture {
                toggleCollection(collectionId)
            }
        )
    }
}

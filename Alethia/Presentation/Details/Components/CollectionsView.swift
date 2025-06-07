//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//
import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: Constants.Spacing.large),
        GridItem(.flexible(), spacing: Constants.Spacing.large),
    ]
    
    private var collections: [CollectionExtended] {
        vm.details?.collections ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            // Enhanced Header
            NavigationLink(destination: ManageCollectionsView()) {
                Text("Collections")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
            // Content Area
            if collections.isEmpty {
                EmptyStateView()
            } else {
                CollectionsGrid()
            }
        }
        .opacity(vm.inLibrary ? 1 : 0.5)
        .disabled(!vm.inLibrary)
    }
    
    @ViewBuilder
    private func EmptyStateView() -> some View {
        ContentUnavailableView {
            Label("No Collections Yet", systemImage: "folder.badge.plus")
        } description: {
            Text("This item does not belong to any existing collections.")
        } actions: {
            NavigationLink(destination: ManageCollectionsView()) {
                HStack(spacing: Constants.Spacing.minimal) {
                    Text("Manage Collections")
                }
            }
        }
    }
    
    @ViewBuilder
    private func CollectionsGrid() -> some View {
        LazyVGrid(columns: columns, spacing: Constants.Spacing.regular) {
            ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                CollectionCard(collection: collection)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: collections.count)
            }
        }
    }
    
    @ViewBuilder
    private func CollectionCard(collection: CollectionExtended) -> some View {
        let collectionColor = Color(hex: collection.collection.color)
        
        VStack(spacing: Constants.Spacing.regular) {
            // Icon Container with Enhanced Styling
            ZStack {
                Circle()
                    .fill(collectionColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(collectionColor.opacity(0.3), lineWidth: 1.5)
                    )
                
                Image(systemName: collection.collection.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(collectionColor)
            }
            
            // Collection Name
            Text(collection.collection.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Constants.Padding.screen)
        .padding(.horizontal, Constants.Padding.regular)
        .background(
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.card)
                .fill(collectionColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.card)
                        .stroke(collectionColor.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(.rect)
        .hoverEffect(.highlight)
    }
}

private struct ManageCollectionsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: Constants.Spacing.large) {
                Text("Manage Collections")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Collection management functionality coming soon...")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

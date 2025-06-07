//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//
import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    private var collections: [CollectionExtended] {
        vm.details?.collections ?? []
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            // Enhanced Header
            NavigationLink {
                ManageCollectionsView()
                    .environmentObject(vm)
            } label: {
                HStack {
                    Text("Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Content Area
            if collections.isEmpty {
                EmptyStateView()
            } else {
                CollectionsList()
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
            Text("This manga doesn't belong to any collections.")
        } actions: {
            NavigationLink {
                ManageCollectionsView()
                    .environmentObject(vm)
            } label: {
                Text("Manage Collections")
            }
        }
    }
    
    @ViewBuilder
    private func CollectionsList() -> some View {
        VStack(spacing: Constants.Spacing.regular) {
            ForEach(Array(collections.enumerated()), id: \.element.id) { index, collection in
                CollectionRow(collection: collection)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05), value: collections.count)
            }
        }
    }
    
    @ViewBuilder
    private func CollectionRow(collection: CollectionExtended) -> some View {
        CollectionRowView(
            collection: collection,
            isSelected: true,
            showSelected: false
        )
        .hoverEffect(.highlight)
    }
}

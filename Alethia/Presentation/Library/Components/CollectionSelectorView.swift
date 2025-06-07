//
//  CollectionSelectorView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/2/2025.
//

import SwiftUI

struct CollectionSelectorView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @State private var showingNewCollectionSheet: Bool = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                DefaultCollectionPill()
                
                ForEach(vm.collections) { collection in
                    CollectionPill(collection)
                }
                
                NewCollectionPill()
            }
            .padding(.horizontal, Constants.Padding.screen)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .scrollDismissesKeyboard(.immediately)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private func DefaultCollectionPill() -> some View {
        let isSelected = vm.activeCollection == nil
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.setActiveCollection(nil)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 14, weight: .medium))
                
                Text("All")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemFill))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private func CollectionPill(_ collection: CollectionExtended) -> some View {
        let isSelected = vm.activeCollection == collection.collection
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.setActiveCollection(collection.collection)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: collection.collection.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(collection.collection.name)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                
                if collection.itemCount > 0 {
                    Text("\(collection.itemCount)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: collection.collection.color) : Color(.secondarySystemFill))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private func NewCollectionPill() -> some View {
        Button {
            showingNewCollectionSheet = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                
                Text("New")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingNewCollectionSheet) {
            NewCollectionView { name, color, icon in
                do {
                    try vm.createCollection(name: name, color: color, icon: icon)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Supporting Styles

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

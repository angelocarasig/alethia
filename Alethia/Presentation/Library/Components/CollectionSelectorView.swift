//
//  CollectionSelectorView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/2/2025.
//

import Core
import SwiftUI

struct CollectionSelectorView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @State private var showingNewCollectionSheet: Bool = false
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .Spacing.large) {
                DefaultCollectionPill()
                
                ForEach(vm.collections) { collection in
                    CollectionPill(collection)
                }
                
                NewCollectionPill()
            }
            .padding(.bottom, .Padding.regular)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private func DefaultCollectionPill() -> some View {
        let isSelected = vm.activeCollection == nil
        
        HStack(spacing: .Spacing.regular) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            
            if isSelected {
                Text("All")
                    .font(.system(size: 15, weight: .medium))
                    .transition(.scale(scale: 0.8, anchor: .leading).combined(with: .opacity))
            }
        }
        .foregroundColor(isSelected ? .background : .text)
        .padding(.horizontal, isSelected ? .Padding.screen : .Spacing.large)
        .padding(.vertical, .Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: .Corner.button, style: .continuous)
                .fill(isSelected ? Color.text : Color.tint)
        )
        .tappable {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                vm.setActiveCollection(nil)
            }
        }
    }
    
    @ViewBuilder
    private func CollectionPill(_ collection: CollectionExtended) -> some View {
        let isSelected = vm.activeCollection == collection.collection
        
        HStack(spacing: .Spacing.regular) {
            Image(systemName: collection.collection.icon)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 20, height: 20)
            
            if isSelected {
                HStack(spacing: .Spacing.minimal) {
                    Text(collection.collection.name)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(1)
                    
                    Text("\(collection.itemCount)")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                .transition(.scale(scale: 0.8, anchor: .leading).combined(with: .opacity))
            }
        }
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, isSelected ? .Padding.screen : .Spacing.large)
        .padding(.vertical, .Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: .Corner.button, style: .continuous)
                .fill(isSelected ? Color(hex: collection.collection.color) : Color.tint)
        )
        .tappable {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    vm.setActiveCollection(nil)
                } else {
                    vm.setActiveCollection(collection.collection)
                }
            }
        }
    }
    
    @ViewBuilder
    private func NewCollectionPill() -> some View {
        HStack(spacing: .Spacing.regular) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16, weight: .medium))
            
            Text("New")
                .font(.system(size: 15, weight: .medium))
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, .Padding.screen)
        .padding(.vertical, .Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: .Corner.button, style: .continuous)
                .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
        )
        .tappable {
            showingNewCollectionSheet = true
        }
        .sheet(isPresented: $showingNewCollectionSheet) {
            CollectionFormView(mode: .create) { name, color, icon in
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

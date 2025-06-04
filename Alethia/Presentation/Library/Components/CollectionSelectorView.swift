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
            HStack(spacing: Constants.Spacing.toolbar) {
                DefaultCollectionCell()
                
                ForEach(vm.collections) { collection in
                    CollectionCell(collection)
                }
                
                NewCollectionCell()
            }
            .scrollTargetLayout()
            .padding(
                EdgeInsets(
                    top: 4,
                    leading: Constants.Padding.screen,
                    bottom: Constants.Padding.screen,
                    trailing: Constants.Padding.screen
                )
            )
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollBounceBehavior(.basedOnSize)
    }
    
    @ViewBuilder
    private func DefaultCollectionCell() -> some View {
        VStack {
            let isSelected = vm.activeCollection == nil
            
            Text("Default")
                .font(.headline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .text : .secondary)
            if isSelected {
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(.accentColor)
            }
        }
        .onTapGesture {
            withAnimation {
                vm.setActiveCollection(nil)
            }
        }
    }
    
    @ViewBuilder
    private func CollectionCell(_ collection: CollectionExtended) -> some View {
        VStack {
            let isSelected = vm.activeCollection == collection.collection
            
            HStack(spacing: Constants.Spacing.minimal) {
                Text(collection.collection.name)
                    .font(.headline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .text : .secondary)
                
                Text("(\(collection.itemCount))")
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
            }
            
            if isSelected {
                Rectangle()
                    .frame(height: 4)
                    .foregroundColor(Color(hex: collection.collection.color))
            }
        }
        .frame(minWidth: 50)
        .onTapGesture {
            withAnimation {
                vm.setActiveCollection(collection.collection)
            }
        }
    }
    
    @ViewBuilder
    private func NewCollectionCell() -> some View {
        Button {
            withAnimation {
                vm.setActiveCollection(nil)
                showingNewCollectionSheet = true
            }
        } label: {
            HStack {
                Text("New")
                Image(systemName: "plus")
            }
            .font(.headline)
            .fontWeight(.regular)
            .foregroundColor(.secondary)
            .shimmer()
        }
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

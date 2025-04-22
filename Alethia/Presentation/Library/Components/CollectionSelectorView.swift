//
//  CollectionSelectorView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/2/2025.
//

import SwiftUI

struct CollectionSelectorView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                //                if settings.libraryShowDefault {
                DefaultCollectionCell()
                //                }
                
                ForEach(vm.collections) { collection in
                    CollectionCell(collection)
                }
                
                //                if !settings.libraryHideNewTab {
                //                    NewCollectionCell()
                //                }
            }
            .scrollTargetLayout()
            .padding(.horizontal)
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
    private func CollectionCell(_ collection: Collection) -> some View {
        VStack {
            let isSelected = vm.activeCollection == collection
            
            Text(collection.name)
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
                vm.setActiveCollection(collection)
            }
        }
    }
    
    @ViewBuilder
    private func NewCollectionCell() -> some View {
        Button {
            print("hi")
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
        .onTapGesture {
            withAnimation {
                vm.setActiveCollection(nil)
            }
        }
    }
}

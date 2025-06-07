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
            HStack(spacing: Constants.Spacing.large) {
                DefaultCollectionPill()
                
                ForEach(vm.collections) { collection in
                    CollectionPill(collection)
                }
                
                NewCollectionPill()
            }
            .padding(.bottom, Constants.Padding.regular)
        }
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
            HStack(spacing: Constants.Spacing.regular) {
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
            .padding(.horizontal, isSelected ? Constants.Padding.screen : Constants.Spacing.large)
            .padding(.vertical, Constants.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.button, style: .continuous)
                    .fill(isSelected ? Color.text : Color.tint)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private func CollectionPill(_ collection: CollectionExtended) -> some View {
        let isSelected = vm.activeCollection == collection.collection
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    vm.setActiveCollection(nil)
                } else {
                    vm.setActiveCollection(collection.collection)
                }
            }
        } label: {
            HStack(spacing: Constants.Spacing.regular) {
                Image(systemName: collection.collection.icon)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 20, height: 20)
                
                if isSelected {
                    HStack(spacing: Constants.Spacing.minimal) {
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
            .padding(.horizontal, isSelected ? Constants.Padding.screen : Constants.Spacing.large)
            .padding(.vertical, Constants.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.button, style: .continuous)
                    .fill(isSelected ? Color(hex: collection.collection.color) : Color.tint)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    @ViewBuilder
    private func NewCollectionPill() -> some View {
        Button {
            showingNewCollectionSheet = true
        } label: {
            HStack(spacing: Constants.Spacing.regular) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                
                Text("New")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, Constants.Padding.screen)
            .padding(.vertical, Constants.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.button, style: .continuous)
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

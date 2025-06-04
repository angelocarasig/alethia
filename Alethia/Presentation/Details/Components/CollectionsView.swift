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
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
            NavigationLink(destination: ManageCollectionsView()) {
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
            
            LazyVGrid(columns: columns, spacing: Constants.Spacing.regular) {
                ForEach(vm.details?.collections ?? [], id: \.id) { collection in
                    CollectionCard(collection: collection)
                }
            }
        }
        .opacity(vm.inLibrary ? 1 : 0.5)
    }
    
    @ViewBuilder
    private func CollectionCard(collection: Collection) -> some View {
        HStack(spacing: Constants.Spacing.regular) {
            let selectedColor = Color(hex: collection.color)
            ZStack {
                Circle()
                    .fill(selectedColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: collection.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(selectedColor)
            }
            
            Text(collection.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Constants.Padding.regular)
        .padding(.vertical, Constants.Padding.regular)
        .background(Color(hex: collection.color).opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                .stroke(Color(hex: collection.color).opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(Constants.Corner.Radius.regular)
    }
}

private struct ManageCollectionsView: View {
    var body: some View {
        Text("Hi")
    }
}

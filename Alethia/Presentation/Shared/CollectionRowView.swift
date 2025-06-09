//
//  CollectionRowView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import SwiftUI

struct CollectionRowView: View {
    let name: String
    let itemCount: Int
    let icon: String
    let color: Color
    let isSelected: Bool
    let showSelected: Bool
    
    init(
        name: String,
        itemCount: Int,
        icon: String,
        color: Color,
        isSelected: Bool = false,
        showSelected: Bool = true
    ) {
        self.name = name
        self.itemCount = itemCount
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.showSelected = showSelected
    }
    
    init(
        collection: CollectionExtended,
        isSelected: Bool = false,
        showSelected: Bool = true
    ) {
        self.name = collection.collection.name
        self.itemCount = collection.itemCount
        self.icon = collection.collection.icon
        self.color = Color(hex: collection.collection.color)
        self.isSelected = isSelected
        self.showSelected = showSelected
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.large) {
            // Collection Icon
            CollectionIcon(icon: icon, color: color, isSelected: isSelected)
            
            // Collection Info
            CollectionInfo(name: name, itemCount: itemCount)
            
            Spacer()
            
            if showSelected {
                SelectionIndicator(isSelected: isSelected, color: color)
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, 12)
        .background(
            CollectionBackground(isSelected: isSelected, showSelected: showSelected, color: color)
        )
        .contentShape(.rect)
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(isSelected ? color : Color.secondary.opacity(0.3), lineWidth: 2)
                .frame(width: 22, height: 22)
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
}

private struct CollectionIcon: View {
    let icon: String
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(color)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

private struct CollectionInfo: View {
    let name: String
    let itemCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            HStack(spacing: Constants.Spacing.minimal) {
                Image(systemName: "book.closed")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text("^[\(itemCount) item](inflect: true)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CollectionBackground: View {
    let isSelected: Bool
    let showSelected: Bool
    let color: Color
    
    var showIndicator: Bool {
        showSelected && isSelected
    }
    
    let cornerRadius = Constants.Corner.Radius.button
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(isSelected ? color.opacity(0.1) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        showIndicator ? color.opacity(0.4) : Color.secondary.opacity(0.1),
                        lineWidth: showIndicator ? 2 : (isSelected ? 0 : 1)
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : .black.opacity(0.05),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
    }
}

// MARK: - Used in preview for new collection
struct CollectionRowPreview: View {
    let name: String
    let itemCount: Int
    let icon: String
    let color: Color
    
    var body: some View {
        CollectionRowView(
            name: name.isEmpty ? "Collection Name" : name,
            itemCount: itemCount,
            icon: icon,
            color: color,
            isSelected: true
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

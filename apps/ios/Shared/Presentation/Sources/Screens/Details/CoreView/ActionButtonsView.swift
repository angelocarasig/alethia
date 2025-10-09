//
//  ActionButtonsView.swift
//  Presentation
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct ActionButtonsView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var inLibrary: Bool = false
    @State private var sourcePresent: Bool = false
    @State private var addingToLibrary: Bool = false
    @State private var isAddingOrigin: Bool = false
    
    var body: some View {
        HStack(spacing: dimensions.spacing.regular) {
            ActionButton(isActive: inLibrary) {
                if inLibrary {
                    // TODO: remove from library
                } else {
                    addingToLibrary = true
                }
            } content: {
                HStack {
                    Image(systemName: inLibrary ? "heart.fill" : "plus")
                    Text(inLibrary ? "In Library" : "Add to Library")
                }
            }
            .sheet(isPresented: $addingToLibrary) {
                // TODO: add to library sheet
                Text("Add to Library")
            }
            
            ActionButton(isActive: sourcePresent) {
                // TODO: add origin
            } content: {
                if !isAddingOrigin {
                    HStack {
                        Image(systemName: "plus.square.dashed")
                        Text("Add Source")
                    }
                } else {
                    ProgressView()
                }
            }
            .disabled(isAddingOrigin)
            
            Menu {
                Button {} label: { Label("Edit Details", systemImage: "pencil") }
                Button {} label: { Label("Refresh", systemImage: "rectangle.and.text.magnifyingglass") }
                Button {} label: { Label("Merge Wizard", systemImage: "plus.rectangle.fill.on.rectangle.fill") }
                Divider()
                Button {} label: { Label("Download All Chapters", systemImage: "arrow.down.circle.fill") }
                Button {} label: { Label("Remove All Downloads", systemImage: "trash.fill") }
                Button {} label: { Label("Mark All As Read", systemImage: "checkmark.circle.fill") }
                Button {} label: { Label("Mark All As Unread", systemImage: "x.circle.fill") }
            } label: {
                Image(systemName: "ellipsis")
                    .padding(.horizontal, dimensions.padding.minimal)
                    .lineLimit(1)
                    .fontWeight(.medium)
                    .frame(width: 50, height: 50)
                    .foregroundColor(theme.colors.background)
                    .background(theme.colors.foreground, in: .rect(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(height: 50)
        .animation(.easeInOut(duration: 0.3), value: inLibrary)
    }
    
    @ViewBuilder
    private func ActionButton<Content: View>(
        isActive: Bool,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(.horizontal, dimensions.padding.minimal)
            .lineLimit(1)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(isActive ? theme.colors.background : theme.colors.foreground)
            .background(isActive ? theme.colors.foreground : theme.colors.tint, in: .rect(cornerRadius: 12, style: .continuous))
            .cornerRadius(dimensions.cornerRadius.button)
            .tappable(action: action)
    }
}

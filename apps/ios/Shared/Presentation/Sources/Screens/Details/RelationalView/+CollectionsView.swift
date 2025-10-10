//
//  +CollectionsView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct CollectionsView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let title: String
    let collections: [Collection]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            DetailHeader(title: "Collections")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if collections.isEmpty {
                emptyState
            } else {
                collectionsList
            }
            
            addCollectionButton
        }
        .sheet(isPresented: $showingAddSheet) {
            // TODO: add collection selection sheet
            Text("Add to Collection")
        }
    }
}

// MARK: - Collections List
extension CollectionsView {
    @ViewBuilder
    private var collectionsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: dimensions.spacing.regular) {
                ForEach(collections, id: \.id) { collection in
                    collectionChip(collection)
                }
            }
        }
    }
    
    @ViewBuilder
    private func collectionChip(_ collection: Collection) -> some View {
        HStack(spacing: dimensions.spacing.regular) {
            Image(systemName: "rectangle.stack.fill")
                .font(.caption)
                .foregroundColor(theme.colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(collection.updatedAt.timeAgo())
                    .font(.caption2)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
            }
            
            Menu {
                Button {} label: {
                    Label("View Collection", systemImage: "rectangle.stack")
                }
                
                Divider()
                
                Button {} label: {
                    Label("Edit Collection", systemImage: "pencil")
                }
                
                Button(role: .destructive) {} label: {
                    Label("Remove from Collection", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.3))
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
    }
}

// MARK: - Empty State
extension CollectionsView {
    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView {
            Label("Not in any collections", systemImage: "rectangle.stack.badge.plus")
        } description: {
            Text("Add to organize and group related manga")
        }
        .frame(height: 180)
    }
}

// MARK: - Add Button
extension CollectionsView {
    @ViewBuilder
    private var addCollectionButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            HStack(spacing: dimensions.spacing.regular) {
                Image(systemName: "plus.circle.fill")
                    .font(.body)
                
                Text("Add to Collection")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(theme.colors.accent)
            .padding(dimensions.padding.screen)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(dimensions.cornerRadius.button)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        CollectionsView(
            title: "Solo Leveling",
            collections: [
                Collection(
                    id: 1,
                    name: "Currently Reading",
                    description: "Manga I'm actively following",
                    createdAt: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
                    updatedAt: Calendar.current.date(byAdding: .month, value: -2, to: .now)!
                ),
                Collection(
                    id: 2,
                    name: "Top Tier Isekai",
                    description: "The best isekai manga I've read",
                    createdAt: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
                    updatedAt: Calendar.current.date(byAdding: .month, value: -2, to: .now)!
                ),
                Collection(
                    id: 3,
                    name: "To Re-read",
                    description: "",
                    createdAt: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
                    updatedAt: Calendar.current.date(byAdding: .month, value: -2, to: .now)!
                ),
                Collection(
                    id: 4,
                    name: "Favorites",
                    description: "My all-time favorites",
                    createdAt: Calendar.current.date(byAdding: .year, value: -1, to: .now)!,
                    updatedAt: Calendar.current.date(byAdding: .month, value: -2, to: .now)!
                )
            ]
        )
        .padding(.horizontal)
    }
}

#Preview("Empty State") {
    ScrollView {
        CollectionsView(title: "One Piece", collections: [])
            .padding(.horizontal)
    }
}

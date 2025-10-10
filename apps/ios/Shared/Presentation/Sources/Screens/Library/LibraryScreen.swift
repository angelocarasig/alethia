//
//  LibraryScreen.swift
//  Presentation
//
//  Created by Assistant on 11/10/2025.
//

import SwiftUI
import Domain
import Composition

public struct LibraryScreen: View {
    @State private var vm = LibraryViewModel()
    @State private var showingFilters = false
    
    @Namespace private var namespace
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: dimensions.spacing.large), count: 3)
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingFilters) {
                    LibraryFiltersSheet()
                        .environment(vm)
                }
                .onAppear {
                    vm.startObserving()
                }
                .onDisappear {
                    vm.stopObserving()
                }
        }
        .environment(vm)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if vm.loading && vm.entries.isEmpty {
            Spinner(text: "Loading library...", size: .large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.error, vm.entries.isEmpty {
            errorView(error)
        } else if vm.entries.isEmpty {
            emptyStateView
        } else {
            libraryContent
        }
    }
    
    private var libraryContent: some View {
        ScrollView {
            VStack(spacing: dimensions.spacing.screen) {
                searchSection
                collectionsSection
                
                LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
                    ForEach(vm.entries, id: \.slug) { entry in
                        SourceCard(id: entry.slug, entry: entry, namespace: namespace)
                        .onAppear {
                            // trigger pagination when last items appear
                            if entry == vm.entries.last {
                                vm.loadMore()
                            }
                        }
                    }
                    
                    // loading more indicator
                    if vm.loadingMore {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                                .fill(theme.colors.tint)
                                .aspectRatio(11/16, contentMode: .fit)
                                .shimmer()
                        }
                    }
                }
                .padding(.horizontal, dimensions.padding.screen)
                
                // show total count
                if !vm.entries.isEmpty {
                    Text("\(vm.totalCount) items total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, dimensions.padding.regular)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                vm.refresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    continuation.resume()
                }
            }
        }
    }
    
    private var searchSection: some View {
        Searchbar(
            searchText: Binding(
                get: { vm.searchText },
                set: { newValue in
                    vm.searchText = newValue
                    vm.startObserving() // live search
                }
            ),
            placeholder: "Search library..."
        )
        .padding(.horizontal, dimensions.padding.screen)
    }
    
    private var collectionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: dimensions.spacing.regular) {
                CollectionChip(
                    label: "All",
                    count: vm.totalCount,
                    isSelected: vm.selectedCollection == nil,
                    action: {
                        vm.selectedCollection = nil
                        vm.startObserving()
                    }
                )
                
                // TODO: replace with real collections when implemented
                ForEach(MockData.collections) { collection in
                    CollectionChip(
                        label: collection.name,
                        count: collection.count,
                        isSelected: vm.selectedCollection == collection.id,
                        action: {
                            vm.selectedCollection = collection.id
                            vm.startObserving()
                        }
                    )
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
        }
    }
    
    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("An Error Occurred", systemImage: "exclamationmark.triangle.fill")
        } description: {
            VStack(spacing: dimensions.spacing.large) {
                Text("Something went wrong loading your library")
                    .font(.headline)
                    .fontWeight(.regular)
                
                Text(error.localizedDescription)
                    .fontDesign(.monospaced)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, dimensions.padding.regular)
        } actions: {
            Button("Retry") {
                vm.startObserving()
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Your library is empty",
            systemImage: "books.vertical",
            description: Text(vm.emptyStateMessage)
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingFilters = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(.primary)
                    .if(vm.hasActiveFilters) { view in
                        view.overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(theme.colors.appRed)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
            }
        }
    }
}

// MARK: - Supporting Views

private struct UnreadBadge: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, dimensions.padding.minimal * 1.5)
            .padding(.vertical, dimensions.padding.minimal / 2)
            .background(theme.colors.appRed)
            .clipShape(Capsule())
    }
}

private struct CollectionChip: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: dimensions.spacing.minimal) {
                Text(label)
                    .font(.subheadline)
                
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, dimensions.padding.minimal * 1.5)
                    .padding(.vertical, dimensions.padding.minimal / 2)
                    .background(isSelected ? Color.white.opacity(0.2) : theme.colors.foreground.opacity(0.1))
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? .white : theme.colors.foreground)
            .padding(.horizontal, dimensions.padding.regular * 1.75)
            .padding(.vertical, dimensions.padding.regular)
            .background(isSelected ? theme.colors.accent : theme.colors.tint)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mock Data (temporary)

private struct MockCollection: Identifiable {
    let id = UUID().uuidString
    let name: String
    let count: Int
}

private struct MockData {
    static let collections = [
        MockCollection(name: "Favorites", count: 12),
        MockCollection(name: "Currently Reading", count: 8),
        MockCollection(name: "Shounen", count: 45)
    ]
}

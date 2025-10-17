//
//  LibraryScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 11/10/2025.
//

import SwiftUI
import Domain
import Composition

public struct LibraryScreen: View {
    @State private var vm = LibraryViewModel()
    @State private var showingFilters = false
    @State private var scrollPosition = ScrollPosition()
    
    @Namespace private var namespace
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private let gridColumnCount = 3
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content
                    .scrollPosition($scrollPosition)
                    .refreshable { await vm.refresh() }
                
                scrollToTop
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { filters }
            .sheet(isPresented: $showingFilters) {
                LibraryFiltersSheet()
                    .environment(vm)
            }
            .task {
                vm.startObserving()
                vm.startObservingCollections()
            }
        }
        .environment(vm)
    }
}

// MARK: - Content Sections
private extension LibraryScreen {
    @ViewBuilder
    var content: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: dimensions.spacing.screen) {
                search
                collections
                entries
            }
            .padding(.vertical, dimensions.padding.screen)
        }
    }
    
    @ViewBuilder
    var search: some View {
        VStack(spacing: dimensions.spacing.regular) {
            Searchbar(
                searchText: $vm.searchText,
                placeholder: "Search library...",
                onXTapped: vm.clearSearchText
            )
            
            if !vm.searchText.isEmpty {
                NavigationLink {
                    Text("TODO")
                } label: {
                    HStack {
                        Image(systemName: "globe")
                            .font(.subheadline)
                        Text("Search everywhere for '\(vm.searchText)'")
                            .font(.subheadline)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(dimensions.padding.screen)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(dimensions.cornerRadius.regular)
                }
            }
            
            if shouldShowRecentSearches {
                RecentSearches(
                    searches: vm.recentSearches,
                    onSelect: { vm.searchText = $0 }
                )
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .animation(theme.animations.spring, value: vm.searchText)
    }
    
    @ViewBuilder
    var collections: some View {
        if shouldShowCollections {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: dimensions.spacing.regular) {
                    CollectionChip(
                        label: "All",
                        count: vm.totalCount,
                        isSelected: vm.selectedCollection == nil,
                        action: selectAllCollections
                    )
                    
                    ForEach(vm.collections, id: \.id) { collection in
                        CollectionChip(
                            label: collection.name,
                            count: collection.count,
                            isSelected: vm.selectedCollection == collection.id,
                            action: { selectCollection(collection.id) }
                        )
                    }
                }
                .padding(.horizontal, dimensions.padding.screen)
            }
        }
    }
    
    @ViewBuilder
    var entries: some View {
        if isInitialLoading {
            LoadingGrid(columns: gridColumns)
        } else if hasError {
            error
        } else if isLoadingAfterQuery {
            LoadingGrid(columns: gridColumns)
        } else if isEmpty {
            empty
        } else {
            grid
            
            HStack(spacing: dimensions.spacing.regular) {
                Text("\(vm.totalCount)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .contentTransition(.numericText())
                
                Text("items in library")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, dimensions.padding.regular)
            .transition(.push(from: .bottom).combined(with: .opacity))
            .animation(theme.animations.spring, value: vm.totalCount)
        }
    }
    
    @ViewBuilder
    var grid: some View {
        LazyVGrid(columns: gridColumns, spacing: dimensions.spacing.minimal) {
            ForEach(vm.entries, id: \.slug) { entry in
                NavigationLink {
                    DetailsScreen(entry: entry)
                        .navigationTransition(.zoom(sourceID: entry.slug, in: namespace))
                } label: {
                    EntryCard(entry: entry, lineLimit: 2)
                        .id(entry.slug)
                        .matchedTransitionSource(id: entry.slug, in: namespace)
                }
                .onAppear { loadMoreIfNeeded(for: entry) }
            }
            
            if vm.loadingMore {
                LoadingIndicators()
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .animation(theme.animations.spring, value: vm.entriesVersion)
    }
    
    @ViewBuilder
    var error: some View {
        ContentUnavailableView {
            Label("An Error Occurred", systemImage: "exclamationmark.triangle.fill")
        } description: {
            VStack(spacing: dimensions.spacing.large) {
                Text("Something went wrong loading your library")
                    .font(.headline)
                    .fontWeight(.regular)
                
                if let error = vm.error {
                    Text(error.localizedDescription)
                        .fontDesign(.monospaced)
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, dimensions.padding.regular)
        } actions: {
            Button("Retry") {
                vm.startObserving()
                vm.startObservingCollections()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, dimensions.padding.screen)
    }
    
    @ViewBuilder
    var empty: some View {
        ContentUnavailableView {
            Label(
                vm.hasActiveFilters ? "No Results" : "Your library is empty",
                systemImage: vm.hasActiveFilters ? "magnifyingglass" : "books.vertical"
            )
        } description: {
            Text(vm.emptyStateMessage)
        } actions: {
            if vm.hasActiveFilters {
                Button("Clear Filters") { vm.resetFilters() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.top, dimensions.padding.screen)
        .transition(.opacity.combined(with: .scale))
    }
    
    @ViewBuilder
    var scrollToTop: some View {
        if shouldShowScrollToTop {
            Button(action: scrollToTopAction) {
                Image(systemName: "arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(theme.colors.accent)
                    .clipShape(.circle)
                    .shadow(radius: 4)
            }
            .padding(dimensions.padding.screen)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Toolbar
private extension LibraryScreen {
    @ToolbarContentBuilder
    var filters: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { showingFilters = true }) {
                ZStack {
                    Image(systemName: "line.3.horizontal.decrease")
                    
                    if vm.hasActiveFilters {
                        Circle()
                            .fill(theme.colors.appRed)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                    }
                }
                .animation(theme.animations.spring, value: vm.activeFilterCount)
            }
        }
    }
}

// MARK: - Computed
private extension LibraryScreen {
    var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: dimensions.spacing.minimal),
            count: gridColumnCount
        )
    }
    
    var isInitialLoading: Bool {
        vm.loading && vm.entries.isEmpty && !vm.hasInitiallyLoaded
    }
    
    var hasError: Bool {
        vm.error != nil && vm.entries.isEmpty
    }
    
    var isEmpty: Bool {
        vm.entries.isEmpty && !vm.loading && !vm.isRefreshing
    }
    
    var isLoadingAfterQuery: Bool {
        vm.entries.isEmpty && vm.loading && vm.hasInitiallyLoaded
    }
    
    var shouldShowCollections: Bool {
        !isInitialLoading
    }
    
    var shouldShowRecentSearches: Bool {
        vm.searchText.isEmpty && !vm.recentSearches.isEmpty
    }
    
    var shouldShowScrollToTop: Bool {
        vm.showScrollToTop && !vm.entries.isEmpty
    }
}

// MARK: - Actions
private extension LibraryScreen {
    func selectAllCollections() {
        vm.selectedCollection = nil
        vm.applyFilters()
    }
    
    func selectCollection(_ id: Int64) {
        vm.selectedCollection = id
        vm.applyFilters()
    }
    
    func loadMoreIfNeeded(for entry: Entry) {
        if vm.shouldLoadMoreWhenAppearing(entry) {
            vm.loadMore()
        }
    }
    
    func scrollToTopAction() {
        withAnimation(theme.animations.spring) {
            scrollPosition.scrollTo(edge: .top)
        }
    }
}

// MARK: - Components

private struct RecentSearches: View {
    let searches: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: dimensions.spacing.minimal) {
                ForEach(searches, id: \.self) { search in
                    Button {
                        withAnimation { onSelect(search) }
                    } label: {
                        Label(search, systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .labelStyle(RecentSearchLabelStyle())
                            .padding(.horizontal, dimensions.padding.screen)
                            .padding(.vertical, dimensions.padding.regular)
                            .background(theme.colors.tint)
                            .clipShape(.capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

private struct RecentSearchLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .font(.caption2)
            configuration.title
                .lineLimit(1)
        }
    }
}

private struct CollectionChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        Button(action: { withAnimation { action() } }) {
            HStack(spacing: dimensions.spacing.minimal) {
                Text(label)
                    .font(.subheadline)
                
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, dimensions.padding.minimal * 1.5)
                    .padding(.vertical, dimensions.padding.minimal / 2)
                    .background(badgeBg)
                    .clipShape(.capsule)
                    .contentTransition(.numericText())
            }
            .foregroundStyle(fg)
            .padding(.horizontal, dimensions.padding.regular * 1.75)
            .padding(.vertical, dimensions.padding.regular)
            .background(bg)
            .clipShape(.capsule)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var fg: Color {
        isSelected ? .white : theme.colors.foreground
    }
    
    private var bg: Color {
        isSelected ? theme.colors.accent : theme.colors.tint
    }
    
    private var badgeBg: Color {
        isSelected
            ? Color.white.opacity(0.2)
            : theme.colors.foreground.opacity(0.1)
    }
}

private struct LoadingGrid: View {
    let columns: [GridItem]
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private let skeletonChipCount = 4
    private let skeletonGridItemCount = 12
    
    var body: some View {
        VStack(spacing: dimensions.spacing.screen) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: dimensions.spacing.regular) {
                    ForEach(0..<skeletonChipCount, id: \.self) { _ in
                        Capsule()
                            .fill(theme.colors.tint)
                            .frame(width: 100, height: 36)
                            .shimmer()
                    }
                }
                .padding(.horizontal, dimensions.padding.screen)
            }
            
            LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
                ForEach(0..<skeletonGridItemCount, id: \.self) { _ in
                    GridItemSkeleton()
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
        }
    }
}

private struct GridItemSkeleton: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private let coverAspectRatio: CGFloat = 11/16
    private let textHeight: CGFloat = 12
    private let shortTextWidth: CGFloat = 60
    private let textCornerRadius: CGFloat = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
            RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                .fill(theme.colors.tint)
                .aspectRatio(coverAspectRatio, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: textCornerRadius)
                    .fill(theme.colors.tint)
                    .frame(height: textHeight)
                
                RoundedRectangle(cornerRadius: textCornerRadius)
                    .fill(theme.colors.tint)
                    .frame(width: shortTextWidth, height: textHeight)
            }
        }
        .padding(.horizontal, dimensions.padding.minimal)
        .shimmer()
    }
}

private struct LoadingIndicators: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private let indicatorCount = 3
    private let coverAspectRatio: CGFloat = 11/16
    private let animationDelayIncrement = 0.05
    
    var body: some View {
        ForEach(0..<indicatorCount, id: \.self) { index in
            RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                .fill(theme.colors.tint)
                .aspectRatio(coverAspectRatio, contentMode: .fit)
                .shimmer()
                .transition(
                    .opacity
                        .combined(with: .scale(scale: 0.9))
                        .animation(
                            theme.animations.spring.delay(Double(index) * animationDelayIncrement)
                        )
                )
        }
    }
}

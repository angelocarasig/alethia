//
//  SourceGridView.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain
import Composition

struct SourceGridView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var vm: SourceGridViewModel
    @State private var showingFilters = false
    @State private var showingSortOptions = false
    @State private var showingTags = false
    @State private var scrollPosition = ScrollPosition()
    @State private var currentPage = 1
    
    @Namespace private var namespace
    
    private let source: Source
    private let preset: SearchPreset
    private let gridColumnCount = 3
    
    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: dimensions.spacing.minimal),
            count: gridColumnCount
        )
    }
    
    init(source: Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        self._vm = State(initialValue: SourceGridViewModel(source: source, preset: preset))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchSection
            
            filterHeader
            
            Divider()
            
            contentView
        }
        .animation(theme.animations.generic, value: vm.isLoadingMore)
        .toolbar {
            toolbar
        }
        .sheet(isPresented: $showingFilters) {
            SourceGridFilterSheet(
                searchText: vm.searchText,
                selectedYear: $vm.selectedYear,
                selectedStatuses: $vm.selectedStatuses,
                selectedLanguages: $vm.selectedLanguages,
                selectedRatings: $vm.selectedRatings,
                availableYears: vm.availableYears,
                availableLanguages: vm.availableLanguages,
                supportsYearFilter: vm.supportsYearFilter,
                supportsStatusFilter: vm.supportsStatusFilter,
                supportsLanguageFilter: vm.supportsLanguageFilter,
                supportsRatingFilter: vm.supportsRatingFilter
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSortOptions) {
            SourceGridSortSheet(
                selectedSort: $vm.selectedSort,
                selectedDirection: $vm.selectedDirection,
                availableSorts: source.search.options.sorting
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTags) {
            SourceGridTagSheet(
                includedTags: $vm.includedTags,
                excludedTags: $vm.excludedTags,
                availableTags: vm.availableTags,
                supportsIncludeTags: vm.supportsIncludeTags,
                supportsExcludeTags: vm.supportsExcludeTags
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .task {
            vm.startObserving()
        }
        .onDisappear {
            vm.stopObserving()
        }
        .refreshable {
            vm.refresh()
        }
        .refreshable { vm.refresh() }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.clearError() }
        } message: {
            if let error = vm.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - toolbar
private extension SourceGridView {
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                #warning("TODO: Save action")
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline)
            }
            .disabled(true)
        }
    }
}

// MARK: - main sections

private extension SourceGridView {
    @ViewBuilder
    var searchSection: some View {
        VStack(spacing: dimensions.spacing.regular) {
            Searchbar(
                searchText: $vm.searchText,
                placeholder: "Search \(source.name)...",
                onXTapped: vm.clearSearchText
            )
            
            if !vm.searchText.isEmpty {
                searchEverywhereLink
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.regular)
        .padding(.bottom, dimensions.padding.minimal)
    }
    
    var searchEverywhereLink: some View {
        NavigationLink {
            Text("TODO: Global Search")
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
    
    var filterHeader: some View {
        SourceGridHeader(
            showingFilters: $showingFilters,
            showingSortOptions: $showingSortOptions,
            showingTags: $showingTags,
            currentPage: currentPage,
            totalPages: vm.totalPages,
            selectedSort: vm.selectedSort,
            selectedDirection: vm.selectedDirection,
            activeFilterCount: vm.activeFilterCount,
            activeTagCount: vm.activeTagCount,
            supportsTagFiltering: vm.supportsIncludeTags || vm.supportsExcludeTags,
            onPageTap: scrollToPage
        )
    }
    
    @ViewBuilder
    var contentView: some View {
        if vm.isLoading && vm.entries.isEmpty {
            loadingView
        } else if vm.entries.isEmpty {
            emptyView
        } else {
            gridScrollView
        }
    }
    
    var loadingView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: dimensions.spacing.minimal) {
                ForEach(0..<12, id: \.self) { _ in
                    GridItemSkeleton()
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular)
        }
    }
    
    var emptyView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text(vm.emptyStateMessage)
        )
        .frame(maxHeight: .infinity)
    }
    
    var gridScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: dimensions.spacing.screen) {
                ForEach(1...vm.totalPages, id: \.self) { page in
                    pageSection(page)
                }
                
                loadMoreSection
            }
            .scrollTargetLayout()
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular)
        }
        .scrollPosition($scrollPosition, anchor: .top)
        .onScrollGeometryChange(for: ScrollProgress.self) { geometry in
            calculateScrollProgress(from: geometry)
        } action: { oldValue, newValue in
            // trigger load more when in last 10% of content and not already loading
            if newValue.percentage >= 0.9 && vm.hasMore && !vm.isLoadingMore {
                vm.loadMore()
            }
            
            // update current page
            if newValue.currentPage != currentPage {
                currentPage = newValue.currentPage
            }
        }
    }
    
    func pageSection(_ page: Int) -> some View {
        VStack(spacing: dimensions.spacing.minimal) {
            PageDivider(page: page)
            
            LazyVGrid(columns: gridColumns, spacing: dimensions.spacing.minimal) {
                ForEach(vm.pageItems(for: page), id: \.slug) { entry in
                    SourceCard(
                        id: "\(preset.id)/\(entry.slug)",
                        entry: entry,
                        namespace: namespace,
                        width: nil // setting nil here to take up grid width
                    )
                }
            }
        }
        .id("page-\(page)")
    }
    
    @ViewBuilder
    var loadMoreSection: some View {
        if vm.isLoadingMore {
            Spinner(size: .small)
                .padding(.vertical, dimensions.padding.screen)
        } else if vm.hasMore {
            Button {
                vm.loadMore()
            } label: {
                HStack(spacing: dimensions.spacing.regular) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(theme.colors.accent)
                    
                    Text("Load More")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.colors.foreground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, dimensions.padding.screen)
                .background(theme.colors.accent.opacity(0.1))
                .cornerRadius(dimensions.cornerRadius.button)
            }
            .buttonStyle(.plain)
            .padding(.top, dimensions.spacing.regular)
        }
    }
}

// MARK: - helper methods

private extension SourceGridView {
    func scrollToPage(_ page: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            scrollPosition.scrollTo(id: "page-\(page)", anchor: .top)
        }
    }
    
    func calculateScrollProgress(from geometry: ScrollGeometry) -> ScrollProgress {
        let contentHeight = geometry.contentSize.height
        let visibleHeight = geometry.containerSize.height
        let scrollableHeight = max(contentHeight - visibleHeight, 1)
        
        let offset = max(geometry.contentOffset.y, 0)
        let percentage = min(offset / scrollableHeight, 1.0)
        
        // calculate current page
        guard vm.totalPages > 1 else {
            return ScrollProgress(percentage: percentage, currentPage: 1)
        }
        
        let pageHeight = contentHeight / CGFloat(vm.totalPages)
        let rawPage = Int((offset / pageHeight).rounded()) + 1
        let calculatedPage = max(1, min(vm.totalPages, rawPage))
        
        return ScrollProgress(percentage: percentage, currentPage: calculatedPage)
    }
}

// MARK: - scroll progress

private struct ScrollProgress: Equatable {
    let percentage: Double
    let currentPage: Int
}

// MARK: - source grid header

private struct SourceGridHeader: View {
    @Binding var showingFilters: Bool
    @Binding var showingSortOptions: Bool
    @Binding var showingTags: Bool
    let currentPage: Int
    let totalPages: Int
    let selectedSort: Search.Options.Sort
    let selectedDirection: SortDirection
    let activeFilterCount: Int
    let activeTagCount: Int
    let supportsTagFiltering: Bool
    let onPageTap: (Int) -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var showingPagePicker = false
    
    var body: some View {
        HStack(spacing: dimensions.spacing.regular) {
            sortButton
            
            filterButton
            
            tagsButton
            
            Spacer()
            
            pageIndicator
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(theme.colors.background)
        .sheet(isPresented: $showingPagePicker) {
            SourceGridPageSheet(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageSelect: { page in
                    showingPagePicker = false
                    onPageTap(page)
                }
            )
            .presentationDetents([.fraction(0.33)])
        }
    }
    
    var sortButton: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Image(systemName: selectedDirection == .ascending ? "arrow.up" : "arrow.down")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(selectedSort.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundColor(theme.colors.foreground)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .tappable {
            showingSortOptions = true
        }
    }
    
    var filterButton: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.caption)
                .fontWeight(.semibold)
            
            if activeFilterCount > 0 {
                Text("(\(activeFilterCount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } else {
                Text("Filters")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(activeFilterCount > 0 ? theme.colors.accent : theme.colors.foreground)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(activeFilterCount > 0 ? theme.colors.accent.opacity(0.1) : theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .tappable {
            showingFilters = true
        }
    }
    
    var tagsButton: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Image(systemName: "tag")
                .font(.caption)
                .fontWeight(.semibold)
            
            if activeTagCount > 0 {
                Text("(\(activeTagCount))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            } else {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .foregroundColor(activeTagCount > 0 ? theme.colors.appPurple : theme.colors.foreground)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(activeTagCount > 0 ? theme.colors.appPurple.opacity(0.1) : theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .opacity(supportsTagFiltering ? 1.0 : 0.5)
        .tappable {
            showingTags = true
        }
        .disabled(!supportsTagFiltering)
    }
    
    var pageIndicator: some View {
        Text("\(currentPage)/\(totalPages)")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(theme.colors.accent)
            .contentTransition(.numericText())
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular)
            .background(theme.colors.accent.opacity(0.1))
            .cornerRadius(dimensions.cornerRadius.button)
            .tappable {
                showingPagePicker = true
            }
            .animation(theme.animations.spring, value: currentPage)
            .animation(theme.animations.spring, value: totalPages)
    }
}

// MARK: - components

private struct PageDivider: View {
    let page: Int
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Text("Page \(page)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.foreground.opacity(0.6))
            
            GeometryReader { geo in
                Path { path in
                    let midY = geo.size.height / 2
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: geo.size.width, y: midY))
                }
                .stroke(theme.colors.foreground.opacity(0.1), lineWidth: 1)
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, dimensions.padding.regular)
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

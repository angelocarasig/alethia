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
    @State private var scrollPosition = ScrollPosition()
    @State private var currentPage = 1
    
    @Namespace private var namespace
    
    private let source: Source
    private let preset: SearchPreset
    private let gridColumnCount = 3
    
    private var columns: [GridItem] {
        let spacing = dimensions.spacing.minimal
        let column = GridItem(.flexible(), spacing: spacing)
        return Array(repeating: column, count: gridColumnCount)
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
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.large)
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
        .task { vm.loadInitialData() }
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
            currentPage: currentPage,
            totalPages: vm.totalPages,
            selectedSort: vm.selectedSort,
            selectedDirection: vm.selectedDirection,
            activeFilterCount: vm.activeFilterCount,
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
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
        ScrollView {
            LazyVStack(spacing: dimensions.spacing.screen) {
                ForEach(1...vm.totalPages, id: \.self) { page in
                    pageSection(page)
                }
                
                loadMoreSection
            }
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
                .id("page-\(page)")
            
            LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
                ForEach(vm.pageItems(for: page), id: \.slug) { entry in
                    SourceCard(
                        id: "\(preset.id)/\(entry.slug)",
                        entry: entry,
                        namespace: namespace
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    var loadMoreSection: some View {
        if vm.isLoadingMore {
            Spinner(text: "Loading more...", size: .medium)
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
        let animation = Animation.spring(response: 0.4, dampingFraction: 0.8)
        withAnimation(animation) {
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
    let currentPage: Int
    let totalPages: Int
    let selectedSort: Search.Options.Sort
    let selectedDirection: SortDirection
    let activeFilterCount: Int
    let onPageTap: (Int) -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var showingPagePicker = false
    
    var body: some View {
        HStack(spacing: dimensions.spacing.regular) {
            sortButton
            filterButton
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
        }
    }
    
    var sortButton: some View {
        HStack(spacing: dimensions.spacing.regular) {
            // sort direction icon
            Image(systemName: selectedDirection == .ascending ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.body)
                .foregroundColor(theme.colors.accent)
                .symbolRenderingMode(.hierarchical)
            
            // sort type
            VStack(alignment: .leading, spacing: 2) {
                Text("Sort")
                    .font(.caption2)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                
                Text(selectedSort.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground)
            }
        }
        .padding(.vertical, dimensions.padding.regular)
        .padding(.horizontal, dimensions.padding.screen)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .tappable {
            showingSortOptions = true
        }
    }
    
    var filterButton: some View {
        HStack(spacing: dimensions.spacing.regular) {
            // filter icon with badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.body)
                    .foregroundColor(activeFilterCount > 0 ? theme.colors.accent : theme.colors.foreground.opacity(0.3))
                    .symbolRenderingMode(.hierarchical)
                
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(theme.colors.appRed)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }
            
            // filter label
            VStack(alignment: .leading, spacing: 2) {
                Text("Filters")
                    .font(.caption2)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                
                Text(activeFilterCount > 0 ? "\(activeFilterCount) Active" : "None")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground)
            }
        }
        .padding(.vertical, dimensions.padding.regular)
        .padding(.horizontal, dimensions.padding.screen)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .tappable {
            showingFilters = true
        }
    }
    
    var pageIndicator: some View {
        VStack(spacing: 4) {
            // page number
            HStack(spacing: 2) {
                Text("\(currentPage)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.accent)
                
                Text("/")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.3))
                
                Text("\(totalPages)")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
            }
            
            // progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // background
                    Capsule()
                        .fill(theme.colors.foreground.opacity(0.1))
                    
                    // progress
                    Capsule()
                        .fill(theme.colors.accent)
                        .frame(width: geo.size.width * CGFloat(currentPage) / CGFloat(totalPages))
                }
            }
            .frame(width: 60, height: 3)
        }
        .tappable {
            showingPagePicker = true
        }
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

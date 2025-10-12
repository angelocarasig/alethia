//
//  LibraryViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 11/10/2025.
//

import SwiftUI
import Domain
import Composition
import Combine


@MainActor
@Observable
/// - When the screen appears, it starts a fresh data stream and shows an initial loading state on the first load.
/// - While fetching new data, the current content stays visible; each new request cancels any in‑flight work to avoid overlap.
/// - Typing in search waits briefly before fetching to avoid excessive requests, but clearing the search reloads immediately to prevent flicker.
/// - Changing filters or sorting saves preferences and triggers a new fetch to reflect the updated criteria.
/// - Scrolling near the end requests the next page and smoothly appends more items for an infinite‑scroll experience.
/// - Pull‑to‑refresh re‑queries the data without clearing what’s on screen until fresh results arrive.
public final class LibraryViewModel {
    @ObservationIgnored
    private let getLibraryMangaUseCase: GetLibraryMangaUseCase
    
    private(set) var entries: [Entry] = []
    private(set) var loading = false
    private(set) var loadingMore = false
    private(set) var error: Error?
    private(set) var totalCount = 0
    private(set) var hasMore = false
    private(set) var isRefreshing = false
    private(set) var entriesVersion = 0
    private(set) var hasInitiallyLoaded = false
    
    private var observationTask: Task<Void, Never>?
    private var lastCursor: LibraryCursor?
    private var searchDebounceTask: Task<Void, Never>?
    
    var searchText = "" {
        didSet {
            guard oldValue != searchText else { return }
            debounceSearch()
        }
    }
    var selectedCollection: String?
    var sortField: LibrarySortField = .alphabetical
    var sortDirection: Domain.SortDirection = .ascending
    var selectedSources: Set<Int64> = []
    var publicationStatus: Set<Status> = []
    var addedDateFilter: DateFilter?
    var updatedDateFilter: DateFilter?
    var showUnreadOnly = false
    var showDownloadedOnly = false
    
    @ObservationIgnored
    private(set) var recentSearches: [String] = []
    private let maxRecentSearches = 5
    
    private let debounceDelay: UInt64 = 300_000_000
    private let loadMoreThreshold = 5
    private let scrollToTopThreshold = 20
    
    init() {
        self.getLibraryMangaUseCase = Injector.makeGetLibraryMangaUseCase()
        loadSavedPreferences()
    }
}

extension LibraryViewModel {
    func startObserving() {
        observationTask?.cancel()
        
        // Begin a new load
        loading = true
        error = nil
        
        if !hasInitiallyLoaded {
            // Initial load: clear and prepare pagination
            resetPaginationState()
        } else {
            // Subsequent query: keep current entries visible (no cache used),
            // but disable pagination on old data while new query is loading.
            lastCursor = nil
            hasMore = false
            loadingMore = false
        }
        
        let query = buildQuery()
        
        observationTask = Task { @MainActor in
            for await result in getLibraryMangaUseCase.execute(query: query) {
                guard !Task.isCancelled else { break }
                handleQueryResult(result)
            }
        }
    }
    
    func refresh() async {
        isRefreshing = true
        startObserving()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    
    func stopObserving() {
        observationTask?.cancel()
        searchDebounceTask?.cancel()
        observationTask = nil
        searchDebounceTask = nil
    }
}

// MARK: - Pagination
extension LibraryViewModel {
    func loadMore() {
        guard canLoadMore else { return }
        
        loadingMore = true
        let query = buildQuery(cursor: lastCursor)
        
        Task { @MainActor in
            for await result in getLibraryMangaUseCase.execute(query: query) {
                guard !Task.isCancelled else { break }
                handlePaginationResult(result)
                break
            }
        }
    }
    
    func shouldLoadMoreWhenAppearing(_ entry: Entry) -> Bool {
        guard let index = entries.firstIndex(where: { $0.slug == entry.slug }) else {
            return false
        }
        return index >= entries.count - loadMoreThreshold && hasMore && !loadingMore
    }
    
    private var canLoadMore: Bool {
        !loadingMore && hasMore && lastCursor != nil && !isRefreshing
    }
}

// MARK: - Filters & Sort (Actions)
extension LibraryViewModel {
    func resetFilters() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            clearAllFilters()
        }
        savePreferences()
        startObserving()
    }
    
    func applyFilters() {
        savePreferences()
        startObserving()
    }
    
    func toggleSortDirection() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            sortDirection = sortDirection == .ascending ? .descending : .ascending
        }
        applyFilters()
    }
    
    func setSortField(_ field: LibrarySortField) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if sortField == field {
                toggleSortDirection()
            } else {
                sortField = field
                sortDirection = .ascending
            }
        }
        applyFilters()
    }
    
    func clearSearchText() {
        let previousText = searchText
        
        // Cancel any pending search so we don't show a stale update
        searchDebounceTask?.cancel()
        searchText = ""
        
        // Kick off a fresh load immediately for the empty query
        startObserving()
        
        if !previousText.isEmpty && !recentSearches.contains(previousText) {
            addToRecentSearches(previousText)
        }
    }
    
    private func clearAllFilters() {
        searchText = ""
        selectedCollection = nil
        sortField = .alphabetical
        sortDirection = .ascending
        selectedSources.removeAll()
        publicationStatus.removeAll()
        addedDateFilter = nil
        updatedDateFilter = nil
        showUnreadOnly = false
        showDownloadedOnly = false
    }
}

// MARK: - Computed Properties
extension LibraryViewModel {
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        selectedCollection != nil ||
        !selectedSources.isEmpty ||
        !publicationStatus.isEmpty ||
        addedDateFilter != nil ||
        updatedDateFilter != nil ||
        showUnreadOnly ||
        showDownloadedOnly
    }
    
    var activeFilterCount: Int {
        [
            !searchText.isEmpty,
            selectedCollection != nil,
            !selectedSources.isEmpty,
            !publicationStatus.isEmpty,
            addedDateFilter != nil,
            updatedDateFilter != nil,
            showUnreadOnly,
            showDownloadedOnly
        ].filter { $0 }.count
    }
    
    var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No results for '\(searchText)'"
        } else if hasActiveFilters {
            return "No items match your current filters"
        } else if selectedCollection != nil {
            return "This collection is empty"
        } else {
            return "Your library is empty. Add manga from Sources to start building your collection"
        }
    }
    
    var showScrollToTop: Bool {
        entries.count > scrollToTopThreshold
    }
}

// MARK: - Search Handling
extension LibraryViewModel {
    private func shouldPerformSearch(query: String) -> Bool {
        query.isEmpty || query.count >= 3
    }
    
    private func debounceSearch() {
        searchDebounceTask?.cancel()
        
        // If the query becomes empty, refresh immediately
        if searchText.isEmpty {
            startObserving()
            return
        }
        
        searchDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: debounceDelay)
            guard !Task.isCancelled, shouldPerformSearch(query: searchText) else { return }
            startObserving()
        }
    }
}

// MARK: - Query
extension LibraryViewModel {
    private func buildQuery(cursor: LibraryCursor? = nil) -> LibraryQuery {
        let sort = LibrarySort(field: sortField, direction: sortDirection)
        let filters = LibraryFilters(
            search: searchText.isEmpty ? nil : searchText,
            collectionId: selectedCollection,
            sourceIds: selectedSources,
            publicationStatus: publicationStatus,
            addedDate: addedDateFilter,
            updatedDate: updatedDateFilter,
            unreadOnly: showUnreadOnly,
            downloadedOnly: showDownloadedOnly
        )
        
        return LibraryQuery(sort: sort, filters: filters, cursor: cursor)
    }
    
    private func resetPaginationState() {
        entries.removeAll()
        lastCursor = nil
        hasMore = false
        loadingMore = false
    }
}

// MARK: - Result Handling
extension LibraryViewModel {
    private func handleQueryResult(_ result: Result<LibraryQueryResult, Error>) {
        switch result {
        case .success(let queryResult):
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                updateStateWithQueryResult(queryResult)
            }
        case .failure(let err):
            error = err
            loading = false
            isRefreshing = false
        }
    }
    
    private func updateStateWithQueryResult(_ queryResult: LibraryQueryResult) {
        entries = queryResult.entries
        totalCount = queryResult.totalCount ?? 0
        hasMore = queryResult.hasMore
        lastCursor = queryResult.nextCursor
        loading = false
        isRefreshing = false
        error = nil
        entriesVersion += 1
        hasInitiallyLoaded = true
    }
    
    private func handlePaginationResult(_ result: Result<LibraryQueryResult, Error>) {
        switch result {
        case .success(let queryResult):
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                appendEntriesWithStaggeredAnimation(queryResult.entries)
                hasMore = queryResult.hasMore
                lastCursor = queryResult.nextCursor
                loadingMore = false
            }
        case .failure:
            loadingMore = false
        }
    }
    
    private func appendEntriesWithStaggeredAnimation(_ newEntries: [Entry]) {
        for (index, entry) in newEntries.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.entries.append(entry)
                }
            }
        }
    }
}

// MARK: - Preferences & Recent Searches
extension LibraryViewModel {
    private func addToRecentSearches(_ search: String) {
        recentSearches.insert(search, at: 0)
        if recentSearches.count > maxRecentSearches {
            recentSearches.removeLast()
        }
    }
    
    private func loadSavedPreferences() {
        if let savedSortField = UserDefaults.standard.string(forKey: "library.sortField"),
           let field = LibrarySortField(rawValue: savedSortField) {
            sortField = field
        }
        
        if let savedDirection = UserDefaults.standard.string(forKey: "library.sortDirection"),
           let direction = Domain.SortDirection(rawValue: savedDirection) {
            sortDirection = direction
        }
        
        showUnreadOnly = UserDefaults.standard.bool(forKey: "library.showUnreadOnly")
        showDownloadedOnly = UserDefaults.standard.bool(forKey: "library.showDownloadedOnly")
        
        if let savedSearches = UserDefaults.standard.stringArray(forKey: "library.recentSearches") {
            recentSearches = Array(savedSearches.prefix(maxRecentSearches))
        }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(sortField.rawValue, forKey: "library.sortField")
        UserDefaults.standard.set(sortDirection.rawValue, forKey: "library.sortDirection")
        UserDefaults.standard.set(showUnreadOnly, forKey: "library.showUnreadOnly")
        UserDefaults.standard.set(showDownloadedOnly, forKey: "library.showDownloadedOnly")
        UserDefaults.standard.set(recentSearches, forKey: "library.recentSearches")
    }
}

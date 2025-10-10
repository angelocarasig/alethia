//
//  LibraryViewModel.swift
//  Presentation
//
//  Created by Assistant on 11/10/2025.
//

import SwiftUI
import Domain
import Composition

@MainActor
@Observable
public final class LibraryViewModel {
    // MARK: - Dependencies
    @ObservationIgnored
    private let getLibraryMangaUseCase: GetLibraryMangaUseCase
    
    // MARK: - State
    private(set) var entries: [Entry] = []
    private(set) var loading: Bool = false
    private(set) var loadingMore: Bool = false
    private(set) var error: Error?
    private(set) var totalCount: Int = 0
    private(set) var hasMore: Bool = false
    
    private var observationTask: Task<Void, Never>?
    private var lastCursor: LibraryCursor?
    
    // MARK: - Filters & Sort
    var searchText = ""
    var selectedCollection: String? = nil
    var sortField: LibrarySortField = .alphabetical
    var sortDirection: Domain.SortDirection = .ascending
    var selectedSources: Set<Int64> = []
    var publicationStatus: Set<Status> = []
    var addedDateFilter: DateFilter?
    var updatedDateFilter: DateFilter?
    var showUnreadOnly = false
    var showDownloadedOnly = false
    
    // MARK: - Initialization
    
    init() {
        self.getLibraryMangaUseCase = Injector.makeGetLibraryMangaUseCase()
        loadSavedPreferences()
    }
    
    // MARK: - Public Methods
    
    func startObserving() {
        observationTask?.cancel()
        entries.removeAll()
        lastCursor = nil
        loading = true
        error = nil
        
        let query = buildQuery()
        
        observationTask = Task { @MainActor in
            for await result in getLibraryMangaUseCase.execute(query: query) {
                if Task.isCancelled { break }
                
                switch result {
                case .success(let queryResult):
                    self.entries = queryResult.entries
                    self.totalCount = queryResult.totalCount ?? 0
                    self.hasMore = queryResult.hasMore
                    self.lastCursor = queryResult.nextCursor
                    self.loading = false
                    self.error = nil
                    
                case .failure(let err):
                    self.error = err
                    self.loading = false
                }
            }
        }
    }
    
    func loadMore() {
        guard !loadingMore, hasMore, let cursor = lastCursor else { return }
        
        loadingMore = true
        let query = buildQuery(cursor: cursor)
        
        Task { @MainActor in
            for await result in getLibraryMangaUseCase.execute(query: query) {
                if Task.isCancelled { break }
                
                switch result {
                case .success(let queryResult):
                    self.entries.append(contentsOf: queryResult.entries)
                    self.hasMore = queryResult.hasMore
                    self.lastCursor = queryResult.nextCursor
                    self.loadingMore = false
                    
                case .failure:
                    self.loadingMore = false
                }
                
                break // only take first result for pagination
            }
        }
    }
    
    func refresh() {
        startObserving()
    }
    
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    func resetFilters() {
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
        savePreferences()
        startObserving() // reload with cleared filters
    }
    
    func applyFilters() {
        savePreferences()
        startObserving() // reload with new filters
    }
    
    // MARK: - Computed Properties
    
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
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedCollection != nil { count += 1 }
        if !selectedSources.isEmpty { count += 1 }
        if !publicationStatus.isEmpty { count += 1 }
        if addedDateFilter != nil { count += 1 }
        if updatedDateFilter != nil { count += 1 }
        if showUnreadOnly { count += 1 }
        if showDownloadedOnly { count += 1 }
        return count
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
    
    // MARK: - Private Methods
    
    private func buildQuery(cursor: LibraryCursor? = nil) -> LibraryQuery {
        let sort = LibrarySort(
            field: sortField,
            direction: sortDirection
        )
        
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
        
        return LibraryQuery(
            sort: sort,
            filters: filters,
            cursor: cursor
        )
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
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(sortField.rawValue, forKey: "library.sortField")
        UserDefaults.standard.set(sortDirection.rawValue, forKey: "library.sortDirection")
        UserDefaults.standard.set(showUnreadOnly, forKey: "library.showUnreadOnly")
        UserDefaults.standard.set(showDownloadedOnly, forKey: "library.showDownloadedOnly")
    }
}

//
//  SourceGridViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import Composition

@MainActor
@Observable
final class SourceGridViewModel {
    // MARK: - State
    private(set) var entries: [Entry] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMore = true
    private(set) var totalCount: Int?
    var errorMessage: String?
    
    // MARK: - Search and Filters
    var searchText: String = ""
    var selectedSort: Search.Options.Sort
    var selectedDirection: SortDirection
    var selectedYear: String?
    var selectedStatuses: Set<Status> = []
    var selectedLanguages: Set<LanguageCode> = []
    var selectedRatings: Set<Classification> = []
    var includedTags: Set<String> = []
    var excludedTags: Set<String> = []
    
    // MARK: - Available Options
    var availableYears: [String] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (1900...currentYear).reversed().map { String($0) }
    }
    
    var availableLanguages: [LanguageCode] {
        source.languages
    }
    
    var availableTags: [SearchTag] {
        source.search.tags
    }
    
    var supportsYearFilter: Bool {
        source.search.options.filtering.contains(.year)
    }
    
    var supportsStatusFilter: Bool {
        source.search.options.filtering.contains(.status)
    }
    
    var supportsLanguageFilter: Bool {
        source.search.options.filtering.contains(.translatedLanguage)
    }
    
    var supportsRatingFilter: Bool {
        source.search.options.filtering.contains(.contentRating)
    }
    
    var supportsIncludeTags: Bool {
        source.search.options.filtering.contains(.includeTag)
    }
    
    var supportsExcludeTags: Bool {
        source.search.options.filtering.contains(.excludeTag)
    }
    
    // MARK: - Pagination
    private var currentPage = 1
    private let pageSize = Constants.Search.defaultPageSize
    
    // MARK: - Dependencies
    private let searchUseCase: SearchWithParamsUseCase
    private let findMatchesUseCase: FindMatchesUseCase
    private let source: Source
    private let preset: SearchPreset
    
    // MARK: - Task Management
    private var searchTask: Task<Void, Never>?
    private var matchTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000 // 300ms
    
    // track active search count to maintain loading state
    private var activeSearchCount = 0
    
    // MARK: - Computed Properties
    var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "No results found for '\(searchText)'"
        }
        if hasActiveFilters {
            return "No results match your current filters"
        }
        return "No manga found for this preset"
    }
    
    var totalPages: Int {
        guard !entries.isEmpty else { return 1 }
        let total = totalCount ?? entries.count
        return max(1, (total + pageSize - 1) / pageSize)
    }
    
    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if selectedYear != nil { count += 1 }
        if !selectedStatuses.isEmpty { count += 1 }
        if !selectedLanguages.isEmpty { count += 1 }
        if !selectedRatings.isEmpty { count += 1 }
        return count
    }
    
    var activeTagCount: Int {
        includedTags.count + excludedTags.count
    }
    
    private var hasActiveFilters: Bool {
        selectedYear != nil ||
        !selectedStatuses.isEmpty ||
        !selectedLanguages.isEmpty ||
        !selectedRatings.isEmpty ||
        !includedTags.isEmpty ||
        !excludedTags.isEmpty
    }
    
    // MARK: - Initialization
    init(
        source: Source,
        preset: SearchPreset,
        searchUseCase: SearchWithParamsUseCase? = nil,
        findMatchesUseCase: FindMatchesUseCase? = nil
    ) {
        self.source = source
        self.preset = preset
        self.selectedSort = preset.sortOption
        self.selectedDirection = preset.sortDirection
        self.searchUseCase = searchUseCase ?? Injector.makeSearchWithParamsUseCase()
        self.findMatchesUseCase = findMatchesUseCase ?? Injector.makeFindMatchesUseCase()
        
        applyPresetFilters()
    }
    
    // MARK: - Public Methods
    func startObserving() {
        observationTask?.cancel()
        
        observationTask = Task { @MainActor in
            var previousState = captureState()
            
            // trigger initial search without blocking
            triggerSearch()
            
            // observe changes with debouncing
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: debounceDelay)
                
                guard !Task.isCancelled else { break }
                
                let currentState = captureState()
                if currentState != previousState {
                    previousState = currentState
                    resetPagination()
                    triggerSearch()  // fire and forget - don't await
                }
            }
        }
    }
    
    func stopObserving() {
        observationTask?.cancel()
        searchTask?.cancel()
        matchTask?.cancel()
        observationTask = nil
        searchTask = nil
        matchTask = nil
        activeSearchCount = 0
    }
    
    func loadMore() {
        guard !isLoading && !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        currentPage += 1
        
        triggerSearch(isLoadingMore: true)
    }
    
    func refresh() {
        resetPagination()
        triggerSearch()
    }
    
    func clearSearchText() {
        searchText = ""
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func pageItems(for page: Int) -> [Entry] {
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, entries.count)
        guard startIndex < entries.count else { return [] }
        return Array(entries[startIndex..<endIndex])
    }
    
    // MARK: - Private Methods - Search
    private func triggerSearch(isLoadingMore: Bool = false) {
        // cancel any existing search
        searchTask?.cancel()
        matchTask?.cancel()
        
        // start new search task without blocking
        searchTask = Task { @MainActor in
            await performSearch(isLoadingMore: isLoadingMore)
        }
    }
    
    private func performSearch(isLoadingMore: Bool = false) async {
        // early cancellation check
        guard !Task.isCancelled else { return }
        
        // increment active search count and set loading state
        activeSearchCount += 1
        if isLoadingMore {
            self.isLoadingMore = true
        } else {
            // only set isLoading if this is the first active search
            if activeSearchCount == 1 {
                isLoading = true
            }
        }
        
        do {
            // build filters
            let filters = buildFilters()
            
            // check cancellation before network call
            try Task.checkCancellation()
            
            // perform search
            let result = try await searchUseCase.execute(
                source: source,
                query: searchText,
                sort: selectedSort,
                direction: selectedDirection,
                filters: filters,
                page: currentPage,
                limit: pageSize
            )
            
            // check cancellation after network call
            try Task.checkCancellation()
            
            // update state
            hasMore = result.hasMore
            totalCount = result.totalCount
            
            // enrich and update entries
            await enrichAndUpdateEntries(result.entries, isLoadingMore: isLoadingMore)
            errorMessage = nil
            
        } catch is CancellationError {
            // cancelled - revert state only if needed
            if isLoadingMore && currentPage > 1 {
                currentPage -= 1
            }
            // don't set error message for cancellation
        } catch let urlError as URLError where urlError.code == .cancelled {
            // handle URLError.cancelled specifically
            if isLoadingMore && currentPage > 1 {
                currentPage -= 1
            }
            // don't set error message for cancellation
        } catch {
            // actual error
            handleError(error)
        }
        
        // decrement active search count
        activeSearchCount -= 1
        
        // only reset loading state if no other searches are active
        if activeSearchCount == 0 {
            if isLoadingMore {
                self.isLoadingMore = false
            } else {
                isLoading = false
            }
        }
    }
    
    private func enrichAndUpdateEntries(_ newEntries: [Entry], isLoadingMore: Bool) async {
        // cancel previous match task
        matchTask?.cancel()
        
        // immediately update with raw entries for fast feedback
        updateEntries(newEntries, isLoadingMore: isLoadingMore)
        
        // then enrich in background
        matchTask = Task { @MainActor in
            for await result in findMatchesUseCase.execute(for: newEntries) {
                guard !Task.isCancelled else { break }
                
                switch result {
                case .success(let enrichedEntries):
                    // only update if not cancelled
                    if !Task.isCancelled {
                        updateEntries(enrichedEntries, isLoadingMore: isLoadingMore)
                    }
                case .failure(let error):
                    // log but don't fail the entire operation
                    print("Failed to enrich entries: \(error)")
                }
            }
        }
    }
    
    private func updateEntries(_ newEntries: [Entry], isLoadingMore: Bool) {
        if isLoadingMore {
            // append for pagination
            entries.append(contentsOf: newEntries)
        } else {
            // replace for new search
            entries = newEntries
        }
    }
    
    private func buildFilters() -> [Search.Options.Filter: Search.Options.FilterValue]? {
        var filters: [Search.Options.Filter: Search.Options.FilterValue] = [:]
        
        if let year = selectedYear {
            filters[.year] = .string(year)
        }
        
        if !selectedStatuses.isEmpty {
            filters[.status] = .stringArray(selectedStatuses.map { $0.rawValue })
        }
        
        if !selectedLanguages.isEmpty {
            filters[.translatedLanguage] = .stringArray(selectedLanguages.map { $0.rawValue })
        }
        
        if !selectedRatings.isEmpty {
            filters[.contentRating] = .stringArray(selectedRatings.map { $0.rawValue })
        }
        
        if !includedTags.isEmpty {
            filters[.includeTag] = .stringArray(Array(includedTags))
        }
        
        if !excludedTags.isEmpty {
            filters[.excludeTag] = .stringArray(Array(excludedTags))
        }
        
        return filters.isEmpty ? nil : filters
    }
    
    private func handleError(_ error: Error) {
        // check if task is cancelled first
        if Task.isCancelled {
            return
        }
        
        // check for all types of cancellation
        if error is CancellationError {
            return
        }
        
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return
        }
        
        // check for domain-level cancellation
        if let dataAccessError = error as? DataAccessError, dataAccessError.isCancellation {
            return
        }
        
        // only show errors for non-cancelled operations
        if let domainError = error as? DomainError {
            // skip if error description is nil (another sign of cancellation)
            if domainError.errorDescription != nil {
                errorMessage = domainError.errorDescription
            }
        } else {
            errorMessage = "An unexpected error occurred"
        }
        
        // revert page increment if loading more failed
        if isLoadingMore && currentPage > 1 {
            currentPage -= 1
        }
    }
    
    private func resetPagination() {
        currentPage = 1
        entries = []
        hasMore = true
        totalCount = nil
        errorMessage = nil
    }
    
    // MARK: - Private Methods - State Management
    private struct SearchState: Equatable {
        let searchText: String
        let sort: Search.Options.Sort
        let direction: SortDirection
        let year: String?
        let statuses: Set<Status>
        let languages: Set<LanguageCode>
        let ratings: Set<Classification>
        let includedTags: Set<String>
        let excludedTags: Set<String>
    }
    
    private func captureState() -> SearchState {
        SearchState(
            searchText: searchText,
            sort: selectedSort,
            direction: selectedDirection,
            year: selectedYear,
            statuses: selectedStatuses,
            languages: selectedLanguages,
            ratings: selectedRatings,
            includedTags: includedTags,
            excludedTags: excludedTags
        )
    }
    
    private func applyPresetFilters() {
        let filters = preset.filters
        guard !filters.isEmpty else { return }
        
        // apply year filter
        if case .string(let year) = filters[.year] {
            selectedYear = year
        }
        
        // apply status filters
        if case .stringArray(let statusStrings) = filters[.status] {
            selectedStatuses = Set(statusStrings.compactMap { Status(rawValue: $0) })
        } else if case .string(let statusString) = filters[.status] {
            if let status = Status(rawValue: statusString) {
                selectedStatuses = Set([status])
            }
        }
        
        // apply language filters
        if case .stringArray(let langCodes) = filters[.translatedLanguage] {
            selectedLanguages = Set(langCodes.map { LanguageCode($0) })
        } else if case .string(let langCode) = filters[.translatedLanguage] {
            selectedLanguages = Set([LanguageCode(langCode)])
        }
        
        // apply rating filters
        if case .stringArray(let ratings) = filters[.contentRating] {
            selectedRatings = Set(ratings.compactMap { Classification(rawValue: $0) })
        } else if case .string(let rating) = filters[.contentRating] {
            if let classification = Classification(rawValue: rating) {
                selectedRatings = Set([classification])
            }
        }
        
        // apply tag filters
        if case .stringArray(let tags) = filters[.includeTag] {
            includedTags = Set(tags)
        } else if case .string(let tag) = filters[.includeTag] {
            includedTags = Set([tag])
        }
        
        if case .stringArray(let tags) = filters[.excludeTag] {
            excludedTags = Set(tags)
        } else if case .string(let tag) = filters[.excludeTag] {
            excludedTags = Set([tag])
        }
    }
}

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
    // state
    private(set) var entries: [Entry] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMore = true
    private(set) var totalCount: Int?
    var errorMessage: String?
    
    // search and filters
    var searchText: String = ""
    var selectedSort: Search.Options.Sort
    var selectedDirection: SortDirection
    var selectedYear: String?
    var selectedStatuses: Set<Status> = []
    var selectedLanguages: Set<LanguageCode> = []
    var selectedRatings: Set<Classification> = []
    var includedTags: Set<String> = []
    var excludedTags: Set<String> = []
    
    // available options - derived from source capabilities
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
    
    // pagination
    private var currentPage = 1
    private let pageSize = Constants.Search.defaultPageSize
    
    // dependencies
    private let searchUseCase: SearchWithParamsUseCase
    private let findMatchesUseCase: FindMatchesUseCase
    private let source: Source
    private let preset: SearchPreset
    
    // task management
    private var searchTask: Task<Void, Never>?
    private var matchTask: Task<Void, Never>?
    private var observationTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000
    
    // computed
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
        !selectedRatings.isEmpty
    }
    
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
    
    func startObserving() {
        observationTask?.cancel()
        
        observationTask = Task { @MainActor in
            var previousState = captureState()
            
            // perform initial search
            await performSearch()
            
            // observe changes with debouncing
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: debounceDelay)
                
                let currentState = captureState()
                if currentState != previousState {
                    previousState = currentState
                    resetPagination()
                    searchTask?.cancel()
                    await performSearch()
                }
            }
        }
    }

    func stopObserving() {
        observationTask?.cancel()
        searchTask?.cancel()
        matchTask?.cancel()
    }
    
    func loadMore() {
        guard !isLoading && !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        currentPage += 1
        
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            await performSearch(isLoadingMore: true)
        }
    }
    
    func refresh() {
        resetPagination()
        searchTask?.cancel()
        
        searchTask = Task { @MainActor in
            await performSearch()
        }
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
    
    // MARK: - preset prefilling
    
    private func applyPresetFilters() {
        let filters = preset.filters
        guard !filters.isEmpty else { return }
        
        if case .string(let year) = filters[.year] {
            selectedYear = year
        }
        
        if case .stringArray(let statusStrings) = filters[.status] {
            selectedStatuses = Set(statusStrings.compactMap { Status(rawValue: $0) })
        } else if case .string(let statusString) = filters[.status] {
            if let status = Status(rawValue: statusString) {
                selectedStatuses = Set([status])
            }
        }
        
        if case .stringArray(let langCodes) = filters[.translatedLanguage] {
            selectedLanguages = Set(langCodes.map { LanguageCode($0) })
        } else if case .string(let langCode) = filters[.translatedLanguage] {
            selectedLanguages = Set([LanguageCode(langCode)])
        }
        
        if case .stringArray(let ratings) = filters[.contentRating] {
            selectedRatings = Set(ratings.compactMap { Classification(rawValue: $0) })
        } else if case .string(let rating) = filters[.contentRating] {
            if let classification = Classification(rawValue: rating) {
                selectedRatings = Set([classification])
            }
        }
        
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
    
    // MARK: - state observation
    
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
    
    // MARK: - private methods
    
    private func resetPagination() {
        currentPage = 1
        entries = []
        hasMore = true
        totalCount = nil
        errorMessage = nil
    }
    
    private func performSearch(isLoadingMore: Bool = false) async {
        if isLoadingMore {
            self.isLoadingMore = true
        } else {
            isLoading = true
        }
        
        do {
            let filters = buildFilters()
            
            let result = try await searchUseCase.execute(
                source: source,
                query: searchText,
                sort: selectedSort,
                direction: selectedDirection,
                filters: filters,
                page: currentPage,
                limit: pageSize
            )
            
            hasMore = result.hasMore
            totalCount = result.totalCount
            await enrichEntries(result.entries, isLoadingMore: isLoadingMore)
            errorMessage = nil
        } catch {
            handleError(error)
        }
        
        if self.isLoadingMore {
            self.isLoadingMore = false
        } else {
            isLoading = false
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
    
    private func enrichEntries(_ newEntries: [Entry], isLoadingMore: Bool) async {
        matchTask?.cancel()
        
        matchTask = Task { @MainActor in
            for await result in findMatchesUseCase.execute(for: newEntries) {
                guard !Task.isCancelled else { break }
                
                switch result {
                case .success(let enrichedEntries):
                    updateEntries(enrichedEntries, isLoadingMore: isLoadingMore)
                case .failure(let error):
                    print("Failed to enrich entries: \(error)")
                    updateEntries(newEntries, isLoadingMore: isLoadingMore)
                }
            }
        }
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func updateEntries(_ newEntries: [Entry], isLoadingMore: Bool) {
        if isLoadingMore {
            entries.append(contentsOf: newEntries)
        } else {
            entries = newEntries
        }
    }
    
    private func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            errorMessage = domainError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
        
        if self.isLoadingMore {
            self.isLoadingMore = false
            if currentPage > 1 {
                currentPage -= 1
            }
        } else {
            isLoading = false
        }
    }
}

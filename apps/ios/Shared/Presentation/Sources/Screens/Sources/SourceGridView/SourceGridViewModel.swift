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
    var searchText: String = "" {
        didSet {
            guard oldValue != searchText else { return }
            debounceSearch()
        }
    }
    var selectedSort: Search.Options.Sort
    var selectedDirection: SortDirection
    var selectedYears: Set<String> = []
    var selectedStatuses: Set<Status> = []
    var selectedLanguages: Set<LanguageCode> = []
    var selectedRatings: Set<Classification> = []
    
    // available options
    let availableYears = ["2024", "2023", "2022", "2021", "2020"]
    let availableLanguages = [
        LanguageCode("en"),
        LanguageCode("ja"),
        LanguageCode("ko"),
        LanguageCode("zh")
    ]
    
    // pagination
    private var currentPage = 1
    private let pageSize = Constants.Search.defaultPageSize
    
    // track if data has been loaded
    private var hasLoadedInitialData = false
    
    // dependencies
    private let searchUseCase: SearchWithPresetUseCase
    private let findMatchesUseCase: FindMatchesUseCase
    private let source: Source
    private let preset: SearchPreset
    
    // task management
    private var searchTask: Task<Void, Never>?
    private var matchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private let debounceDelay: UInt64 = 300_000_000
    
    // track if search text came from preset to avoid debouncing on init
    private var isInitialLoad = true
    
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
        if !selectedYears.isEmpty { count += 1 }
        if !selectedStatuses.isEmpty { count += 1 }
        if !selectedLanguages.isEmpty { count += 1 }
        if !selectedRatings.isEmpty { count += 1 }
        return count
    }
    
    private var hasActiveFilters: Bool {
        !selectedYears.isEmpty ||
        !selectedStatuses.isEmpty ||
        !selectedLanguages.isEmpty ||
        !selectedRatings.isEmpty
    }
    
    init(
        source: Source,
        preset: SearchPreset,
        searchUseCase: SearchWithPresetUseCase? = nil,
        findMatchesUseCase: FindMatchesUseCase? = nil
    ) {
        self.source = source
        self.preset = preset
        self.selectedSort = preset.sortOption
        self.selectedDirection = preset.sortDirection
        self.searchUseCase = searchUseCase ?? Injector.makeSearchWithPresetUseCase()
        self.findMatchesUseCase = findMatchesUseCase ?? Injector.makeFindMatchesUseCase()
        
        applyPresetFilters()
    }
    
    func loadInitialData() {
        guard !isLoading, !hasLoadedInitialData else { return }
        cancelAllTasks()
        resetState()
        isLoading = true
        
        searchTask = Task { @MainActor in
            await performSearch()
            isInitialLoad = false
            hasLoadedInitialData = true
        }
    }
    
    func loadMore() {
        guard !isLoading && !isLoadingMore && hasMore else { return }
        isLoadingMore = true
        currentPage += 1
        
        searchTask = Task { @MainActor in
            await performSearch(isLoadingMore: true)
        }
    }
    
    func refresh() {
        hasLoadedInitialData = false
        loadInitialData()
    }
    
    func clearSearchText() {
        searchText = ""
        debounceTask?.cancel()
        hasLoadedInitialData = false
        loadInitialData()
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
        
        if case .stringArray(let years) = filters[.year] {
            selectedYears = Set(years)
        } else if case .string(let year) = filters[.year] {
            selectedYears = Set([year])
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
    }
    
    // MARK: - private methods
    
    private func debounceSearch() {
        guard !isInitialLoad else { return }
        
        debounceTask?.cancel()
        
        guard !searchText.isEmpty else {
            hasLoadedInitialData = false
            loadInitialData()
            return
        }
        
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: debounceDelay)
            guard !Task.isCancelled else { return }
            hasLoadedInitialData = false
            loadInitialData()
        }
    }
    
    private func performSearch(isLoadingMore: Bool = false) async {
        do {
            let result = try await searchUseCase.execute(
                source: source,
                preset: preset,
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
        
        if isLoadingMore {
            self.isLoadingMore = false
        } else {
            isLoading = false
        }
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
        
        isLoading = false
        isLoadingMore = false
        
        if currentPage > 1 {
            currentPage -= 1
        }
    }
    
    private func cancelAllTasks() {
        searchTask?.cancel()
        matchTask?.cancel()
        debounceTask?.cancel()
    }
    
    private func resetState() {
        entries = []
        currentPage = 1
        hasMore = true
        errorMessage = nil
        totalCount = nil
    }
}

//
//  SearchGridViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain
import Composition

@MainActor
@Observable
final class SearchGridViewModel {
    // state
    private(set) var entries: [Entry] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var hasMore = true
    var errorMessage: String?
    
    // pagination
    private var currentPage = 1
    private let pageSize = Constants.Search.defaultPageSize
    
    // dependencies
    private let searchUseCase: SearchWithPresetUseCase
    private let findMatchesUseCase: FindMatchesUseCase
    
    // search parameters
    private let source: Source
    private let preset: SearchPreset
    
    // task management
    private var searchTask: Task<Void, Never>?
    private var matchTask: Task<Void, Never>?
    
    init(
        source: Source,
        preset: SearchPreset,
        searchUseCase: SearchWithPresetUseCase? = nil,
        findMatchesUseCase: FindMatchesUseCase? = nil
    ) {
        self.source = source
        self.preset = preset
        self.searchUseCase = searchUseCase ?? Injector.makeSearchWithPresetUseCase()
        self.findMatchesUseCase = findMatchesUseCase ?? Injector.makeFindMatchesUseCase()
    }
    
    // MARK: - Public Methods
    
    func loadInitialData() {
        guard !isLoading else { return }
        
        // cancel any existing tasks
        searchTask?.cancel()
        matchTask?.cancel()
        
        // reset state
        entries = []
        currentPage = 1
        hasMore = true
        errorMessage = nil
        isLoading = true
        
        searchTask = Task { @MainActor in
            await performSearch()
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
        loadInitialData()
    }
    
    func shouldLoadMore(for entry: Entry) -> Bool {
        // trigger load more when we're near the end (last 5 items)
        guard let index = entries.firstIndex(where: { $0.slug == entry.slug }) else { return false }
        return index >= entries.count - 5 && hasMore && !isLoadingMore
    }
    
    // MARK: - Private Methods
    
    private func performSearch(isLoadingMore: Bool = false) async {
        do {
            let result = try await searchUseCase.execute(
                source: source,
                preset: preset,
                page: currentPage,
                limit: pageSize
            )
            
            // update has more flag
            hasMore = result.hasMore
            
            // enrich entries with match states
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
        // cancel any existing match task
        matchTask?.cancel()
        
        matchTask = Task { @MainActor in
            for await result in findMatchesUseCase.execute(for: newEntries) {
                switch result {
                case .success(let enrichedEntries):
                    if isLoadingMore {
                        // append to existing entries
                        entries.append(contentsOf: enrichedEntries)
                    } else {
                        // replace entries for initial load
                        entries = enrichedEntries
                    }
                    
                case .failure(let error):
                    // log error but don't stop - use unenriched entries
                    print("Failed to enrich entries: \(error)")
                    if isLoadingMore {
                        entries.append(contentsOf: newEntries)
                    } else {
                        entries = newEntries
                    }
                }
            }
        }
        
        // wait for the first result or timeout after 2 seconds
        // this prevents ui from hanging if enrichment is slow
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    private func handleError(_ error: Error) {
        if let domainError = error as? DomainError {
            errorMessage = domainError.errorDescription
        } else {
            errorMessage = "An unexpected error occurred"
        }
        
        // reset loading states
        isLoading = false
        isLoadingMore = false
        
        // if error on page > 1, revert page number
        if currentPage > 1 {
            currentPage -= 1
        }
    }
}

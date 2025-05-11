//
//  SearchSourceView.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI
import Combine
import ScrollViewLoader

struct SearchSourceView: View {
    @Namespace private var namespace
    @StateObject private var vm: ViewModel
    
    init(source: Source, initialSearchValue: String = "") {
        _vm = StateObject(
            wrappedValue: ViewModel(
                source: source,
                initialSearchValue: initialSearchValue
            )
        )
    }
    
    var body: some View {
        VStack {
            SearchBar(searchText: $vm.search)
                .padding(.horizontal, Constants.Padding.regular)
                .onSubmit { vm.startNewSearch() }
            
            ZStack {
                if vm.items.isEmpty && vm.loading {
                    SkeletonGridView()
                } else {
                    VStack {
                        CollectionViewGrid(
                            data: vm.items,
                            content: { entry in
                                SourceCardView(
                                    namespace: namespace,
                                    source: vm.source,
                                    entry: entry
                                )
                            },
                            columns: 3,
                            spacing: Constants.Spacing.minimal,
                            contentInsets: NSDirectionalEdgeInsets(
                                top: 8, leading: 8, bottom: 8, trailing: 8
                            ),
                            onReachedBottom: {
                                guard !vm.loading, !vm.noMoreContent else { return }
                                vm.page += 1
                                Task { await vm.loadPage() }
                            },
                            onItemTapped: { entry in
                                // Handle item tap
                                print("Tapped: \(entry.title)")
                            }
                        )
                        
                        // Next-page loader
                        if vm.loading && !vm.items.isEmpty {
                            ProgressView()
                                .padding()
                        }
                        
                        if vm.noMoreContent {
                            Text("No More Results")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding()
                        }
                    }
                    .refreshable {
                        await vm.refresh()
                    }
                }
            }
            .task {
                if !vm.search.isEmpty && vm.firstLoad {
                    vm.startNewSearch()
                }
            }
        }
        .navigationTitle(vm.source.name)
    }
    
    // MARK: – Skeleton
    
    @ViewBuilder
    private func SkeletonGridView() -> some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(0..<15, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 175)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 14)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 14)
                    }
                    .padding(.vertical, Constants.Padding.regular)
                    .padding(.horizontal, Constants.Padding.minimal)
                }
            }
            .padding(.horizontal, Constants.Padding.minimal)
        }
    }
}

// MARK: – ViewModel

private extension SearchSourceView {
    final class ViewModel: ObservableObject {
        // Inputs
        let source: Source
        @Published var search: String
        
        // Pagination + state
        @Published var page: Int = 0
        @Published private(set) var items: [Entry] = []
        @Published private(set) var loading: Bool = false
        @Published private(set) var noMoreContent: Bool = false
        @Published private(set) var firstLoad: Bool = true
        
        // Internal
        private var allEntries: [Entry] = []
        private var entriesById: [String: Entry] = [:] // Cache by ID for faster updates
        private var observationCancellable: AnyCancellable?
        private var currentTask: Task<Void, Never>?
        
        private let searchUseCase: SearchSourceUseCase
        private let observeMatchEntriesUseCase: ObserveMatchEntriesUseCase
        
        init(source: Source, initialSearchValue: String) {
            self.source = source
            self.search = initialSearchValue
            
            self.searchUseCase = DependencyInjector.shared.makeSearchSourceUseCase()
            self.observeMatchEntriesUseCase = DependencyInjector.shared.makeObserveMatchEntriesUseCase()
            
            // Initialize the persistent observation
            setupObservation()
        }
        
        deinit {
            currentTask?.cancel()
            observationCancellable?.cancel()
        }
        
        private func setupObservation() {
            // Create a single observation pipeline
            observationCancellable = observeMatchEntriesUseCase
                .execute(entries: [])
                .receive(on: RunLoop.main)
                .sink { [weak self] updatedEntries in
                    guard let self = self else { return }
                    
                    // Apply updates to our cache
                    for entry in updatedEntries {
                        self.entriesById[entry.id] = entry
                    }
                    
                    // Reconstruct items array from our cache, maintaining order
                    self.items = self.allEntries.compactMap { entry in
                        return self.entriesById[entry.id]
                    }
                }
        }
        
        func startNewSearch() {
            // Reset everything
            currentTask?.cancel()
            allEntries = []
            entriesById = [:]
            page = 0
            items = []
            noMoreContent = false
            firstLoad = true
            
            Task { await loadPage() }
        }
        
        @MainActor
        func refresh() async {
            currentTask?.cancel()
            allEntries = []
            entriesById = [:]
            page = 0
            items = []
            noMoreContent = false
            firstLoad = true
            
            await loadPage()
        }
        
        @MainActor
        func loadPage() async {
            // Cancel any in-flight load
            currentTask?.cancel()
            
            currentTask = Task {
                defer {
                    if !Task.isCancelled {
                        withAnimation {
                            firstLoad = false
                            loading = false
                        }
                    }
                    currentTask = nil
                }
                
                withAnimation {
                    loading = true
                }
                
                do {
                    let newEntries = try await searchUseCase.execute(
                        source: source,
                        query: search,
                        page: page
                    )
                    
                    // If none returned, we're done
                    if newEntries.isEmpty {
                        noMoreContent = true
                        return
                    }
                    
                    // Store new entries in our order-preserving array
                    allEntries.append(contentsOf: newEntries)
                    
                    // Update the initial state of our items
                    for entry in newEntries {
                        entriesById[entry.id] = entry
                    }
                    
                    // Update items with the current state
                    withAnimation {
                        items = allEntries.compactMap { entry in
                            return entriesById[entry.id]
                        }
                    }
                    
                    // Trigger observation for new entries only
                    // This is more efficient than observing all entries again
                    _ = observeMatchEntriesUseCase
                        .execute(entries: newEntries)
                        .sink { _ in }
                } catch {
                    print("Search error for page \(page):", error)
                }
            }
            
            await currentTask?.value
        }
    }
}

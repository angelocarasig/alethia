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
    
    // 3 equal-width flexible columns
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
    ]
    
    var body: some View {
        VStack {
            SearchBar(searchText: $vm.search)
                .onSubmit {
                    vm.startNewSearch()
                }
                .padding(.horizontal, 10)
            
            ScrollView {
                if vm.items.isEmpty && vm.loading {
                    SkeletonGridView()
                }
                
                LazyVGrid(columns: columns) {
                    ForEach(vm.items, id: \.id) { entry in
                        SourceCardView(
                            namespace: namespace,
                            source: vm.source,
                            entry: entry
                        )
                    }
                }
                
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
            .onPullToRefresh {
                await vm.refresh()
            }
            .shouldLoadMore(bottomDistance: .absolute(50), waitForHeightChange: .always) {
                guard !vm.loading, !vm.noMoreContent else { return }
                vm.page += 1
                Task { await vm.loadPage() }
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
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<30, id: \.self) { _ in
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
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 4)
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
        @Published private(set) var items: [Entry] = [] {
            didSet { print("Updated: \(items.count)")}
        }
        @Published private(set) var loading: Bool = false
        @Published private(set) var noMoreContent: Bool = false
        
        @Published private(set) var firstLoad: Bool = true
        
        // Internal
        private var raw: [Entry] = []
        private var cancellables: Set<AnyCancellable> = []
        private var currentTask: Task<Void, Never>?
        
        private let searchUseCase: SearchSourceUseCase
        private let observeMatchEntriesUseCase: ObserveMatchEntriesUseCase
        
        init(source: Source, initialSearchValue: String) {
            self.source = source
            self.search = initialSearchValue
            
            self.searchUseCase = DependencyInjector.shared.makeSearchSourceUseCase()
            self.observeMatchEntriesUseCase = DependencyInjector.shared.makeObserveMatchEntriesUseCase()
        }
        
        deinit {
            currentTask?.cancel()
        }
        
        func startNewSearch() {
            // reset everything
            page = 0
            items.removeAll()
            noMoreContent = false
            firstLoad = true
            
            Task { await loadPage() }
        }
        
        @MainActor
        func refresh() async {
            page = 0
            noMoreContent = false
            items.removeAll()
            firstLoad = true
            await loadPage()
        }
        
        @MainActor
        func loadPage() async {
            // cancel any in-flight load
            currentTask?.cancel()
            
            currentTask = Task {
                defer {
                    if !Task.isCancelled {
                        firstLoad = false
                        loading = false
                    }
                    currentTask = nil
                }
                
                loading = true
                do {
                    let newEntries = try await searchUseCase.execute(
                        source: source,
                        query: search,
                        page: page
                    )
                    // if none returned, we’re done
                    if newEntries.isEmpty {
                        noMoreContent = true
                        return
                    }
                    
                    raw.append(contentsOf: newEntries)
                    bind()
                } catch {
                    print("Search error for page \(page):", error)
                }
            }
            
            await currentTask?.value
        }
        
        private func bind() {
            guard !raw.isEmpty else { return }
            
            cancellables.removeAll()
            
            observeMatchEntriesUseCase
                .execute(entries: raw)
                .receive(on: RunLoop.main)
                .sink { [weak self] updated in
                    print("Received: \(updated.count) updated entries")
                    self?.items = updated
                }
                .store(in: &cancellables)
        }
    }
}

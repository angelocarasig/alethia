//
//  SearchSourceView.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI
import Combine

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
                    CollectionViewGrid(
                        data: vm.items,
                        id: \.sourceViewId,
                        columns: 3,
                        spacing: Constants.Spacing.minimal,
                        onReachedBottom: {
                            guard !vm.loading, !vm.items.isEmpty, !vm.noMoreContent else { return }
                            vm.page += 1
                            Task { await vm.loadPage() }
                        },
                        content: { entry in
                            SourceCardView(
                                namespace: namespace,
                                source: vm.source,
                                entry: entry
                            )
                        },
                        footer: {
                            // Footer content for loading and end states
                            if vm.loading && !vm.items.isEmpty {
                                ProgressView()
                                    .padding()
                            } else if vm.noMoreContent {
                                Text("No More Results")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    )
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
                GridItem(.flexible(), spacing: Constants.Spacing.minimal),
                GridItem(.flexible(), spacing: Constants.Spacing.minimal),
                GridItem(.flexible(), spacing: Constants.Spacing.minimal)
            ], spacing: Constants.Spacing.minimal) {
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

private final class ViewModel: ObservableObject {
    // Inputs
    let source: Source
    @Published var search: String
    
    // Pagination + state
    @Published var page: Int = 0
    @Published var items: [Entry] = []
    @Published var loading: Bool = false
    @Published var refreshing: Bool = false
    @Published var firstLoad: Bool = true
    @Published var noMoreContent: Bool = false
    
    // Internal
    private var raw: [Entry] = []
    private var cancellables = Set<AnyCancellable>()
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
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 0
            items.removeAll()
            raw.removeAll()
            noMoreContent = false
            firstLoad = true
        }
        
        Task { await loadPage() }
    }
    
    @MainActor
    func refresh() async {
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 0
            refreshing = true
            items.removeAll()
            raw.removeAll()
            noMoreContent = false
            firstLoad = true
        }
        
        await loadPage()
        
        withAnimation(.easeInOut) {
            refreshing = false
        }
    }
    
    @MainActor
    func loadPage() async {
        // Cancel any in-flight load
        currentTask?.cancel()
        
        currentTask = Task {
            defer {
                if !Task.isCancelled {
                    withAnimation(.easeInOut) {
                        loading = false
                        firstLoad = false
                    }
                }
                currentTask = nil
            }
            
            do {
                withAnimation(.easeInOut) {
                    loading = true
                }
                
                let newEntries = try await searchUseCase.execute(
                    source: source,
                    query: search,
                    page: page
                )
                
                try Task.checkCancellation()
                
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
                self?.items = updated
            }
            .store(in: &cancellables)
    }
}

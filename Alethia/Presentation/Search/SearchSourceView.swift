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
                .onChange(of: vm.search) { vm.searchTextChanged() }
            
            contentView
                .task {
                    if !vm.search.isEmpty && vm.firstLoad {
                        vm.startNewSearch()
                    }
                }
        }
        .navigationTitle(vm.source.name)
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch vm.viewState {
        case .initial:
            InitialSearchStateView()
        case .loading:
            SkeletonGrid()
        case .noResults:
            NoResultsStateView(searchQuery: vm.search) {
                vm.startNewSearch()
            }
        case .error(let message):
            ErrorStateView(message: message) {
                vm.startNewSearch()
            }
        case .content:
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
                    .id("\(vm.page)-\(entry.id)-\(entry.match)")
                },
                footer: {
                    if vm.loading && !vm.items.isEmpty {
                        ProgressView()
                            .padding()
                    } else if vm.noMoreContent && !vm.items.isEmpty {
                        Text("No More Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding()
                            .transition(.opacity)
                    }
                }
            )
            .refreshable {
                await vm.refresh()
            }
        }
    }
}

// MARK: - View Model

private final class ViewModel: ObservableObject {
    enum ViewState {
        case initial
        case loading
        case content
        case noResults
        case error(String)
    }
    
    // Inputs
    let source: Source
    @Published var search: String
    
    // State
    @Published private(set) var viewState: ViewState = .initial
    @Published var page: Int = 1
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
        
        // Set initial state based on whether we have a search term
        self.viewState = initialSearchValue.isEmpty ? .initial : .loading
    }
    
    deinit {
        currentTask?.cancel()
    }
    
    func searchTextChanged() {
        raw.removeAll()
        items.removeAll()
        
        if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewState = .initial
        }
    }
    
    func startNewSearch() {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewState = .initial
            return
        }
        
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 1
            items.removeAll()
            raw.removeAll()
            noMoreContent = false
            firstLoad = true
            viewState = .loading
        }
        
        Task { await loadPage() }
    }
    
    @MainActor
    func refresh() async {
        guard !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            viewState = .initial
            return
        }
        
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 1
            refreshing = true
            items.removeAll()
            raw.removeAll()
            noMoreContent = false
            firstLoad = true
            viewState = .loading
        }
        
        await loadPage()
        
        withAnimation(.easeInOut) {
            refreshing = false
        }
    }
    
    @MainActor
    func loadPage() async {
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
                    if page == 1 {
                        viewState = .noResults
                    } else {
                        noMoreContent = true
                    }
                    return
                }
                
                raw.append(contentsOf: newEntries)
                viewState = .content
                bind()
            } catch {
                print("Search error for page \(page):", error)
                if page == 1 {
                    viewState = .error(error.localizedDescription)
                }
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

// MARK: - State Views

private struct InitialSearchStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Search Manga  \(SymbolsProvider.randomKaomoji)", systemImage: "magnifyingglass.circle")
        } description: {
            Text("Enter a search query to find series")
        }
    }
}

private struct NoResultsStateView: View {
    let searchQuery: String
    let onRetry: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Couldn't find any manga matching \"\(searchQuery)\".")
        } actions: {
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
            
            VStack(spacing: 12) {
                Text("Search Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

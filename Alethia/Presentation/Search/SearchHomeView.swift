//
//  SearchHomeView.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import Core
import SwiftUI
import Combine
import Kingfisher

struct SearchHomeView: View {
    @Namespace private var namespace
    @StateObject private var vm: SearchHomeViewModel
    
    init(initialSearchValue: String = "") {
        _vm = StateObject(
            wrappedValue: SearchHomeViewModel(initialSearchValue: initialSearchValue)
        )
    }
    
    var body: some View {
        VStack {
            SearchBar(searchText: $vm.search)
                .onChange(of: vm.search) { vm.state = .idle }
                .onSubmit { vm.performSearch() }
            
            switch vm.state {
            case .idle:
                EmptySearchView()
                
            case .loading:
                SkeletonView()
                
            case .loaded(let results):
                ResultsView(results: results)
                
            case .failure(let message):
                Text(message)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding(.horizontal, .Padding.regular)
        .navigationTitle("Search")
    }
}

private extension SearchHomeView {
    @ViewBuilder
    private func EmptySearchView() -> some View {
        Spacer().frame(height: 25)
        Text("Search Something").font(.title2)
        Text(SymbolsProvider.randomKaomoji).font(.title2)
    }
    
    @ViewBuilder
    private func SkeletonView() -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 4) {
                ForEach(vm.sources) { source in
                    HeaderView(source: source)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(0..<10, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 10) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 150, height: 150 * 16 / 11)
                                        .shimmer()
                                    
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 130, height: 14)
                                        .shimmer()
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, .Padding.minimal)
                                .frame(width: 150)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func NoContentView() -> some View {
        Text("No Results Found.")
    }
    
    @ViewBuilder
    private  func ResultsView(results: [SearchResult]) -> some View {
        if results.isEmpty {
            NoContentView()
        }
        
        ScrollView(.vertical) {
            ForEach(results, id: \.source.id) { result in
                HeaderView(source: result.source)
                ContentView(source: result.source, entries: result.results)
            }
        }
    }
}

// MARK: Search Results
private extension SearchHomeView {
    @ViewBuilder
    private func HeaderView(source: Source) -> some View {
        NavigationLink(
            destination: SearchSourceView(source: source, initialSearchValue: vm.search)
        ) {
            HStack {
                let iconSize: CGFloat = 40
                KFImage(URL(filePath: source.icon))
                    .setProcessor(RoundCornerImageProcessor(cornerRadius: 8))
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .padding(.trailing, .Padding.regular)
                
                Text(source.name)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .Padding.regular)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func ContentView(source: Source, entries: [Entry]) -> some View {
        if entries.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.6))
                
                Text("No Results")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("We couldn’t find anything for this source.\nTry searching again or check back later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: .Spacing.minimal) {
                    ForEach(entries, id: \.id) { entry in
                        SourceCardView(namespace: namespace, source: source, entry: entry)
                            .frame(width: 150)
                            .id(entry.id)
                    }
                }
            }
        }
    }
}

final class SearchHomeViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(results: [SearchResult])
        case failure(String)
    }
    
    @Published var search: String
    @Published var state: State = .idle
    
    private(set) var sources: [Source] = []
    private var raw: [SearchResult] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let getSourcesUseCase: GetSourcesUseCase
    private let searchSourceUseCase: SearchSourceUseCase
    private let observeMatchEntriesUseCase: ObserveMatchEntriesUseCase
    
    init(initialSearchValue: String = "") {
        self.search = initialSearchValue
        
        self.getSourcesUseCase = DependencyInjector.shared.makeGetSourcesUseCase()
        self.searchSourceUseCase = DependencyInjector.shared.makeSearchSourceUseCase()
        self.observeMatchEntriesUseCase = DependencyInjector.shared.makeObserveMatchEntriesUseCase()
        
        bind(performInitialSearch: !initialSearchValue.isEmpty)
    }
    
    private func bind(performInitialSearch: Bool = false) -> Void {
        getSourcesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sources in
                self?.sources = sources
                    .map { $0.source }
                    .filter { !$0.disabled }
                    .sorted {
                        if $0.pinned != $1.pinned { return $0.pinned }
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
                
                if performInitialSearch {
                    self?.performSearch()
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch() -> Void {
        guard !search.isEmpty else { return }
        
        clearMatchObservations()
        
        let query = search
        let currentSources = sources
        
        Task {
            await MainActor.run { state = .loading }
            
            var results = Array(repeating: [Entry](), count: currentSources.count)
            
            await withTaskGroup(of: (Int, [Entry]).self) { group in
                for (i, source) in currentSources.enumerated() {
                    group.addTask {
                        do {
                            let entries = try await self.searchSourceUseCase
                                .execute(source: source, query: query, page: 0)
                            return (i, entries)
                        } catch {
                            print("Error searching \(source.name): \(error)")
                            return (i, [])
                        }
                    }
                }
                
                for await (i, entries) in group {
                    results[i] = entries
                }
            }
            
            let wrappedResults = zip(currentSources, results)
                .map { SearchResult(source: $0, results: $1) }
            
            await MainActor.run {
                self.raw = wrappedResults
                self.observeMatches()
            }
        }
    }
    
    private func observeMatches() {
        guard !raw.isEmpty else { return }
        
        let allEntries = raw.flatMap { $0.results }
        
        observeMatchEntriesUseCase
            .execute(entries: allEntries)
            .receive(on: RunLoop.main)
            .sink { [weak self] updatedEntries in
                self?.updateResultsWithMatches(updatedEntries)
            }
            .store(in: &cancellables)
    }
    
    private func updateResultsWithMatches(_ updatedEntries: [Entry]) {
        let updatedDict = Dictionary(uniqueKeysWithValues: updatedEntries.map { ($0.id, $0) })
        
        let updatedResults = raw.map { searchResult in
            let updatedResultEntries = searchResult.results.compactMap { entry in
                updatedDict[entry.id] ?? entry
            }
            return SearchResult(source: searchResult.source, results: updatedResultEntries)
        }
        
        state = .loaded(results: updatedResults)
    }
    
    private func clearMatchObservations() {
        cancellables = cancellables.filter { _ in false }
        bind()
    }
}

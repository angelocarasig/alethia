//
//  SourceRouteScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Combine

// MARK: - Main View
struct SourceRouteScreen: View {
    @Namespace private var namespace
    @StateObject private var vm: SourceRouteViewModel
    
    let source: Source
    let route: SourceRoute
    
    init(source: Source, route: SourceRoute) {
        self.source = source
        self.route = route
        self._vm = StateObject(wrappedValue: SourceRouteViewModel(routeId: route.id!))
    }
    
    var body: some View {
        Group {
            switch vm.viewState {
            case .loading:
                SourceRouteSkeletonView()
            case .empty:
                EmptyStateView(message: "No content available")
            case .content:
                contentView
            case .error(let message):
                ErrorStateView(message: message) {
                    Task { await vm.refresh() }
                }
            }
        }
        .navigationTitle(route.name)
        .task {
            await vm.loadInitialContent()
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        CollectionViewGrid(
            data: vm.items,
            id: \.sourceViewId,
            columns: 3,
            spacing: Constants.Spacing.minimal,
            onReachedBottom: {
                Task { await vm.loadNextPage() }
            },
            content: { entry in
                SourceCardView(
                    namespace: namespace,
                    source: source,
                    entry: entry
                )
                .id("\(entry.id)-\(entry.match)")
            },
            footer: {
                bottomStatusView
            }
        )
        .refreshable {
            await vm.refresh()
        }
    }
    
    // MARK: - Bottom Status View
    @ViewBuilder
    private var bottomStatusView: some View {
        if vm.isLoadingMore {
            ProgressView()
                .padding()
        }
        else if vm.hasReachedEnd {
            Text("No More Results")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding()
                .transition(.opacity)
        }
    }
}

// MARK: - View Model
@MainActor
final class SourceRouteViewModel: ObservableObject {
    // MARK: - View State
    enum ViewState {
        case loading
        case empty
        case content
        case error(String)
    }
    
    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var items: [Entry] = []
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasReachedEnd = false
    
    // MARK: - Private Properties
    private let routeId: Int64
    private var currentPage = 1
    private var rawEntries: [Entry] = []
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?
    
    // MARK: - Use Cases
    private let getSourceRouteContent: GetSourceRouteContentUseCase
    private let observeMatchEntries: ObserveMatchEntriesUseCase
    
    // MARK: - Initialization
    init(routeId: Int64) {
        self.routeId = routeId
        let injector = DependencyInjector.shared
        self.getSourceRouteContent = injector.makeGetSourceRouteContentUseCase()
        self.observeMatchEntries = injector.makeObserveMatchEntriesUseCase()
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    // MARK: - Public Methods
    func loadInitialContent() async {
        guard case .loading = viewState else { return }
        await loadContent(isInitial: true)
    }
    
    func loadNextPage() async {
        guard !isLoadingMore, !hasReachedEnd, case .content = viewState else { return }
        currentPage += 1
        await loadContent(isInitial: false)
    }
    
    func refresh() async {
        resetState()
        await loadContent(isInitial: true)
    }
    
    // MARK: - Private Methods
    private func loadContent(isInitial: Bool) async {
        loadTask?.cancel()
        
        loadTask = Task {
            defer { loadTask = nil }
            
            do {
                updateLoadingState(isInitial: isInitial)
                
                let newEntries = try await getSourceRouteContent.execute(
                    sourceRouteId: routeId,
                    page: currentPage
                )
                
                try Task.checkCancellation()
                
                processNewEntries(newEntries, isInitial: isInitial)
            } catch {
                if !Task.isCancelled {
                    handleError(error)
                }
            }
        }
        
        await loadTask?.value
    }
    
    private func updateLoadingState(isInitial: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if isInitial {
                viewState = .loading
            } else {
                isLoadingMore = true
            }
        }
    }
    
    private func processNewEntries(_ newEntries: [Entry], isInitial: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if newEntries.isEmpty {
                if isInitial {
                    viewState = .empty
                } else {
                    hasReachedEnd = true
                }
            } else {
                rawEntries.append(contentsOf: newEntries)
                setupEntriesBinding()
                viewState = .content
            }
            isLoadingMore = false
        }
    }
    
    private func setupEntriesBinding() {
        cancellables.removeAll()
        
        observeMatchEntries
            .execute(entries: rawEntries)
            .receive(on: RunLoop.main)
            .sink { [weak self] matchedEntries in
                self?.items = matchedEntries
            }
            .store(in: &cancellables)
    }
    
    private func handleError(_ error: Error) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentPage == 0 {
                viewState = .error(error.localizedDescription)
            }
            isLoadingMore = false
        }
    }
    
    private func resetState() {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPage = 0
            rawEntries.removeAll()
            items.removeAll()
            hasReachedEnd = false
            viewState = .loading
        }
    }
}

// MARK: - Supporting Views
private struct SourceRouteSkeletonView: View {
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: Constants.Spacing.minimal), count: 3)
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: Constants.Spacing.minimal) {
                ForEach(0..<12, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(.horizontal, Constants.Padding.minimal)
        }
    }
}

private struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 175)
                .shimmer()
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 14)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 14)
                .frame(maxWidth: 100)
        }
        .padding(.vertical, Constants.Padding.regular)
    }
}

private struct EmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

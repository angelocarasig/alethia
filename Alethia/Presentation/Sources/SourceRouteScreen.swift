//
//  SourceRouteScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Combine
import ScrollViewLoader

struct SourceRouteScreen: View {
    @Namespace private var namespace
    @StateObject private var vm = ViewModel()
    
    var source: Source
    var route: SourceRoute
    
    let columns = [
        GridItem(.flexible(), spacing: Constants.Spacing.minimal),
        GridItem(.flexible(), spacing: Constants.Spacing.minimal),
        GridItem(.flexible(), spacing: Constants.Spacing.minimal)
    ]
    
    var body: some View {
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
                                source: source,
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
                            Task { await vm.load(with: route.id!) }
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
                    await vm.refresh(with: route.id!)
                }
            }
        }
        .navigationTitle(route.name)
    }
    
    @ViewBuilder
    private func SkeletonGridView() -> some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(0..<30, id: \.self) { _ in
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
                    .padding(.horizontal, Constants.Padding.minimal)
                }
            }
        }
    }
}

private final class ViewModel: ObservableObject {
    @Published var page: Int = 0
    @Published var items: [Entry] = []
    @Published var loading: Bool = false
    @Published var refreshing: Bool = false
    @Published var firstLoad: Bool = true
    @Published var noMoreContent: Bool = false
    
    /**
     Seperating raw with the `matched` objects which if not done:
     - Lose the original entries (can't reapply match logic)
     - Have to refetch them every time the library changes (wasted effort)
     */
    private var raw: [Entry] = []
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    private let getSourceRouteContentUseCase: GetSourceRouteContentUseCase
    private let observeMatchEntriesUseCase: ObserveMatchEntriesUseCase
    
    init() {
        self.getSourceRouteContentUseCase = DependencyInjector.shared.makeGetSourceRouteContentUseCase()
        self.observeMatchEntriesUseCase = DependencyInjector.shared.makeObserveMatchEntriesUseCase()
    }
    
    deinit {
        currentTask?.cancel()
    }
    
    @MainActor
    func load(with id: Int64) async {
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
                
                print("Fetching for page: \(page)")
                let newEntries = try await getSourceRouteContentUseCase.execute(sourceRouteId: id, page: page)
                
                try Task.checkCancellation()
                
                if newEntries.isEmpty {
                    noMoreContent = true
                    return
                }
                
                raw.append(contentsOf: newEntries)
                bind()
            } catch {
                print("Error: \(error)")
            }
        }
        
        await currentTask?.value
    }
    
    @MainActor
    func refresh(with id: Int64) async {
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 0
            refreshing = true
            items.removeAll()
            raw.removeAll()
            noMoreContent = false
            firstLoad = true
        }
        
        await load(with: id)
        
        withAnimation(.easeInOut) {
            refreshing = false
        }
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

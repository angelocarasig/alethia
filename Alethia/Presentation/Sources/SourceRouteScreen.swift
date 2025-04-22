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
    
    var route: SourceRoute
    
    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        ScrollView() {
            if vm.items.count == 0 && vm.loading {
                SkeletonGridView()
            }
            
            LazyVGrid(columns: columns) {
                ForEach(vm.items, id: \.self) { entry in
                    SourceCardView(
                        namespace: namespace,
                        entry: entry
                    )
                }
            }
            
            if vm.loading && !vm.items.isEmpty {
                ProgressView()
                    .padding()
            }
            
            if vm.noMoreContent {
                Text("No More Content.")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
        }
        .onPullToRefresh {
            await vm.refresh(with: route.id!)
        }
        .task {
            guard vm.firstLoad else { return }
            await vm.load(with: route.id!)
        }
        .shouldLoadMore(bottomDistance: .absolute(50), waitForHeightChange: .always) {
            guard !vm.loading && !vm.noMoreContent && !vm.refreshing else { return }
            vm.page += 1
            await vm.load(with: route.id!)
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
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
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
    
    private var currentTask: Task<Void, Never>?
    private let getSourceRouteContentUseCase: GetSourceRouteContentUseCase
    
    init() {
        self.getSourceRouteContentUseCase = DependencyInjector.shared.makeGetSourceRouteContentUseCase()
    }
    
    deinit {
        currentTask?.cancel()
    }
    
    @MainActor
    func load(with id: Int64) async {
        // Cancel any existing task
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
                let results = try await getSourceRouteContentUseCase.execute(sourceRouteId: id, page: page)
                
                // Check if we were cancelled while waiting
                try Task.checkCancellation()
                
                if results.isEmpty {
                    noMoreContent = true
                    return
                }
                
                withAnimation(.easeInOut) {
                    items.append(contentsOf: results)
                }
            } catch {
                print("Error: \(error)")
            }
        }
        
        await currentTask?.value
    }
    
    @MainActor
    func refresh(with id: Int64) async {
        // Cancel any existing task
        currentTask?.cancel()
        
        withAnimation(.easeInOut) {
            page = 0
            refreshing = true
            items.removeAll()
            noMoreContent = false
            firstLoad = true
        }
        
        await load(with: id)
        
        withAnimation(.easeInOut) {
            refreshing = false
        }
    }
}

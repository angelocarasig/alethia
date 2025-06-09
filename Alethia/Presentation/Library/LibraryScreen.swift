//
//  LibraryScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI

struct LibraryScreen: View {
    @StateObject private var vm = LibraryViewModel()
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            LibraryContent(animation: animation)
                .sheet(isPresented: $vm.showFilters) {
                    LibraryFilterView()
                        .presentationDetents([.medium, .large])
                }
                .sheet(isPresented: $vm.showQueue) {
                    QueueStatusView()
                        .presentationDetents([.medium, .large])
                }
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .environmentObject(vm)
        }
        .task {
            vm.onAppear()
        }
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: Constants.Spacing.toolbar) {
                Button {
                    vm.showQueue = true
                } label: {
                    let operationCount = QueueProvider.shared.operations.count
                    
                    Image(systemName: "hourglass")
                        .overlay(alignment: .topTrailing) {
                            if operationCount > 0 {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.red)
                                    .background(
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 10, height: 10)
                                    )
                                    .offset(x: 4, y: -4)
                                    .scaleEffect(operationCount > 0 ? 1.0 : 0.8)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true),
                                        value: operationCount > 0
                                    )
                            }
                        }
                }
                
                Button {
                    vm.showFilters = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease")
                        .overlay {
                            if !vm.filters.activeFilters.isEmpty {
                                Text("\(vm.filters.activeFilters.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(Constants.Padding.regular)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 10, y: -10)
                            }
                        }
                }
                
                NavigationLink(destination: Text("Hi")) {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

private struct LibraryContent: View {
    @EnvironmentObject private var vm: LibraryViewModel
    let animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            LibraryHeader()
            
            Group {
                switch vm.state {
                case .loading:
                    LoadingState()
                case .empty:
                    EmptyState()
                case .error(let error):
                    ErrorState(error: error)
                case .success:
                    SuccessState(animation: animation)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct LibraryHeader: View {
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        VStack {
            SearchBar(searchText: $vm.filters.searchText)
            
            if !vm.filters.searchText.isEmpty {
                NavigationLink(destination: SearchHomeView(initialSearchValue: vm.filters.searchText)) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.subheadline)
                        Text("Search everywhere for '\(vm.filters.searchText)'")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(Constants.Padding.screen)
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            CollectionSelectorView()
        }
        .padding(.horizontal, Constants.Padding.screen)
        .animation(.easeInOut(duration: 0.3), value: vm.filters.searchText.isEmpty)
        .background(.bar)
    }
}

// MARK: - Content States
private struct LoadingState: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.regular) {
            LoadingView(message: "Loading library \(SymbolsProvider.randomKaomoji)")
        }
    }
}

private struct EmptyState: View {
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        ContentUnavailableView {
            Label("No Content", systemImage: "books.vertical")
        } description: {
            Text(emptyStateMessage)
        } actions: {
            if vm.hasActiveFilters {
                Button("Clear Filters") {
                    vm.clearAllFilters()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var emptyStateMessage: String {
        if !vm.filters.searchText.isEmpty {
            return "No results for '\(vm.filters.searchText)'"
        } else if vm.hasActiveFilters {
            return "No items match your current filters"
        } else if vm.activeCollection != nil {
            return "This collection is empty"
        } else {
            return "Your library is empty"
        }
    }
}

private struct ErrorState: View {
    let error: Error
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                vm.refreshCollection()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct SuccessState: View {
    @EnvironmentObject private var vm: LibraryViewModel
    let animation: Namespace.ID
    
    private let spacing: CGFloat = Constants.Spacing.minimal
    private let topSpacing: CGFloat = 12
    private let columns: Int = 3
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(vm.items, id: \.libraryViewId) { entry in
                    NavigationLink {
                        DetailsScreen(entry: entry, source: nil)
                            .navigationTransition(.zoom(sourceID: entry.transitionId, in: animation))
                    } label: {
                        EntryView(
                            item: entry,
                            lineLimit: 2,
                            showUnread: true
                        )
                        .padding(.bottom, Constants.Padding.regular)
                        .matchedTransitionSource(id: entry.transitionId, in: animation)
                    }
                    .contentShape(.rect)
                    .buttonStyle(.plain)
                    .unread(entry.unread)
                    .id("library-\(entry.libraryViewId)")
                }
            }
            .padding(.top, topSpacing) // to account for unread badges
        }
        .contentMargins(.trailing, Constants.Padding.regular, for: .scrollContent)
        .padding(.vertical, Constants.Padding.screen)
        .refreshable {
            vm.onRefresh()
        }
    }
}

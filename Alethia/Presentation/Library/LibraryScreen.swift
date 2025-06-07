import SwiftUI

// MARK: - LibraryScreen
struct LibraryScreen: View {
    @StateObject private var vm = LibraryViewModel()
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            // Main Content
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
                        .foregroundStyle(operationCount > 0 ? Color.accentColor : Color.secondary)
                }
                
                Button {
                    vm.showFilters = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease")
                        .badge(vm.filters.activeFilters.isEmpty ? nil : "\(vm.filters.activeFilters.count)")
                }
                
                NavigationLink(destination: Text("Hi")) {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

// MARK: - Library Content
private struct LibraryContent: View {
    @EnvironmentObject private var vm: LibraryViewModel
    let animation: Namespace.ID
    
    var body: some View {
        VStack(spacing: 0) {
            LibraryHeader()
            
            // Direct state-based view rendering without ZStack
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

// MARK: - Library Header
private struct LibraryHeader: View {
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        VStack {
            SearchBar(searchText: $vm.filters.searchText)
            
            // Conditional view without extra container
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
                    .padding(.vertical, Constants.Padding.regular)
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
            LoadingView()
            Text("Loading library \(SymbolsProvider.randomKaomoji)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

// MARK: - Success State
private struct SuccessState: View {
    @EnvironmentObject private var vm: LibraryViewModel
    let animation: Namespace.ID
    
    let spacing: CGFloat = Constants.Spacing.regular
    let columns: Int = 3
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(vm.items, id: \.libraryViewId) { EntryGridItem(entry: $0, animation: animation) }
            }
            .padding(.top, 2) // to account for unread badges
            .padding()
            .animation(.smooth(duration: 0.3, extraBounce: 0.1), value: vm.items.map(\.id))
        }
        .refreshable {
            vm.onRefresh()
        }
    }
}

// MARK: - Entry Grid Item
private struct EntryGridItem: View {
    let entry: Entry
    let animation: Namespace.ID
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry, source: nil)
                .navigationTransition(.zoom(sourceID: entry.transitionId, in: animation))
        } label: {
            EntryView(
                item: entry,
                lineLimit: 2,
                showUnread: true
            )
            .matchedTransitionSource(id: entry.transitionId, in: animation)
        }
        .contentShape(.rect)
        .buttonStyle(.plain)
        .unread(entry.unread)
    }
}

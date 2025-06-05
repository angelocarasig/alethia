//
//  LibraryScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI

// MARK: - Main LibraryScreen
struct LibraryScreen: View {
    @StateObject private var vm = LibraryViewModel()
    
    var body: some View {
        NavigationStack {
            LibraryContentView {
                MainHeader()
            } stickyHeader: {
                CollectionSelectorView()
            } background: {
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea()
            } content: {
                ContentStateView()
            }
            .sheet(isPresented: $vm.showFilters) {
                LibraryFilterView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $vm.showQueue) {
                QueueStatusView()
            }
        }
        .environmentObject(vm)
        .onAppear {
            vm.onAppear()
        }
    }
}

// MARK: - LibraryScreen Content Views
private extension LibraryScreen {
    @ViewBuilder
    func ContentStateView() -> some View {
        switch vm.state {
        case .loading:
            LoadingView()
            
        case .empty:
            ContentUnavailableView(
                "Nothing Found",
                systemImage: "books.vertical"
            )
            
        case .success:
            ContentView()
            
        case .error(let error):
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
        }
    }
    
    @ViewBuilder
    func MainHeader() -> some View {
        VStack(alignment: .center, spacing: 0) {
            SearchBar(searchText: $vm.filters.searchText)
                .padding(.horizontal)
                .padding(.bottom, Constants.Padding.regular)
            
            if !vm.filters.searchText.isEmpty {
                NavigationLink(destination: SearchHomeView(initialSearchValue: vm.filters.searchText)) {
                    Text("Search Globally")
                }
            }
        }
        .animation(.easeInOut, value: vm.filters.searchText.isEmpty)
    }
}

// MARK: - LibraryScreen Helper Views
private extension LibraryScreen {
    @ViewBuilder
    func ActiveFiltersOverlay() -> some View {
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

// MARK: - Content Grid View
private struct ContentView: View {
    @Namespace private var namespace
    @EnvironmentObject private var vm: LibraryViewModel
    
    private var columns: Int = 3
    private var spacing: CGFloat = Constants.Spacing.minimal
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(vm.items, id: \.libraryViewId) { entry in
                CardView(namespace: namespace, entry: entry)
            }
        }
        .animation(.smooth, value: vm.items.map(\.id))
        .padding(.top, Constants.Padding.regular)
        .padding(.horizontal, Constants.Padding.regular)
    }
}

// MARK: - Card View
private struct CardView: View {
    let namespace: Namespace.ID
    let entry: Entry
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry, source: nil)
                .navigationTransition(.zoom(sourceID: entry.transitionId, in: namespace))
        } label: {
            EntryView(
                item: entry,
                lineLimit: 2,
                showUnread: true
            )
            .matchedTransitionSource(id: entry.transitionId, in: namespace)
        }
        .unread(entry.unread)
        .padding(.top, Constants.Padding.regular)
    }
}

// MARK: - Library Content View
private struct LibraryContentView<Header: View, StickyHeader: View, Background: View, Content: View>: View {
    var spacing: CGFloat = 10
    
    @ViewBuilder var header: Header
    @ViewBuilder var stickyHeader: StickyHeader
    @ViewBuilder var background: Background
    @ViewBuilder var content: Content
    
    @State private var currentDragOffset: CGFloat = 0
    @State private var previousDragOffset: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var headerSize: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            content
        }
        .onPullToRefresh {
            vm.onRefresh()
        }
        .frame(maxWidth: .infinity)
        .onScrollGeometryChange(for: CGFloat.self, of: scrollOffsetCalculation) { oldValue, newValue in
            scrollOffset = newValue
        }
        .simultaneousGesture(dragGesture)
        .safeAreaInset(edge: .top, spacing: 0) {
            CombinedHeaderView()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            toolbarContent
        }
    }
}

// MARK: - LibraryContentView Computed Properties
private extension LibraryContentView {
    func scrollOffsetCalculation(_ geometry: ScrollGeometry) -> CGFloat {
        geometry.contentOffset.y + geometry.contentInsets.top
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged(handleDragChanged)
            .onEnded(handleDragEnded)
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            leadingTitle
        }
        
        ToolbarItem(placement: .principal) {
            principalTitle
        }
        
        ToolbarItem(placement: .topBarTrailing) {
            trailingButtons
        }
    }
    
    var leadingTitle: some View {
        Text("Library")
            .font(.largeTitle)
            .fontWeight(.bold)
            .opacity(scrollOffset <= 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: scrollOffset <= 0)
    }
    
    var principalTitle: some View {
        Text("Library")
            .font(.headline)
            .fontWeight(.semibold)
            .opacity(scrollOffset > 0 ? 1 : 0)
            .animation(.easeInOut(duration: 0.3), value: scrollOffset > 0)
    }
    
    var trailingButtons: some View {
        HStack(spacing: Constants.Spacing.toolbar) {
            Button {
                vm.showQueue = true
            } label: {
                let operationCount = QueueProvider.shared.operations.count
                
                Image(systemName: "hourglass")
                    .foregroundStyle(operationCount > 0 ? Color.accentColor : Color.tint)
            }
            
            Button {
                vm.showFilters = true
            } label: {
                Image(systemName: "line.horizontal.3.decrease")
                    .overlay(ActiveFiltersOverlay())
            }
            
            NavigationLink(destination: Text("Hi")) {
                Image(systemName: "gearshape")
            }
        }
    }
}

// MARK: - LibraryContentView Methods
private extension LibraryContentView {
    func handleDragChanged(_ value: DragGesture.Value) {
        let dragOffset = -max(0, abs(value.translation.height) - 50) * (value.translation.height < 0 ? -1 : 1)
        
        previousDragOffset = currentDragOffset
        currentDragOffset = dragOffset
        
        let deltaOffset = (currentDragOffset - previousDragOffset).rounded()
        headerOffset = max(min(headerOffset + deltaOffset, headerSize), 0)
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
        withAnimation {
            if headerOffset > (headerSize * 0.5) && scrollOffset > headerSize {
                headerOffset = headerSize
            } else {
                headerOffset = 0
            }
        }
        
        currentDragOffset = 0
        previousDragOffset = 0
    }
    
    @ViewBuilder
    func ActiveFiltersOverlay() -> some View {
        if !vm.filters.activeFilters.isEmpty {
            Text("\(vm.filters.activeFilters.count)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(Constants.Padding.regular)
                .background(Circle().fill(Color.red))
                .offset(x: 10, y: -10)
        }
    }
    
    @ViewBuilder
    func CombinedHeaderView() -> some View {
        VStack(spacing: 0) {
            header
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { newValue in
                    headerSize = newValue + spacing
                }
            
            stickyHeader
        }
        .offset(y: -headerOffset + (headerSize > 0 ? 5 : 0)) // 5 acts as padding for toolbar
        .clipped()
        .background {
            Group{
                if scrollOffset <= 50 {
                    Color.background
                } else {
                    background
                }
            }
            .ignoresSafeArea()
            .offset(y: -headerOffset)
        }
    }
}

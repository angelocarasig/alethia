//
//  LibraryScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI

struct LibraryScreen: View {
    @StateObject private var vm = LibraryViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                LibrarySearch()
                
                CollectionSelectorView()
                
                Group {
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
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Constants.Spacing.toolbar) {
                        Button(action: {
                            vm.showFilters = true
                        }) {
                            Image(systemName: "line.horizontal.3.decrease")
                                .overlay(ActiveFiltersOverlay())
                        }
                        NavigationLink(destination: Text("Hi")) {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showFilters) {
                LibraryFilterView()
                    .presentationDetents([.medium, .large])
            }
        }
        .environmentObject(vm)
        .onAppear {
            vm.onAppear()
        }
    }
    
    @ViewBuilder
    private func ActiveFiltersOverlay() -> some View {
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
    private func LibrarySearch() -> some View {
        VStack(alignment: .center, spacing: 0) {
            SearchBar(searchText: $vm.filters.searchText)
                .padding(.horizontal)
                .padding(.bottom, Constants.Padding.minimal)
            
            if !vm.filters.searchText.isEmpty {
                NavigationLink(destination: SearchHomeView(initialSearchValue: vm.filters.searchText)) {
                    Text("Search Globally")
                }
            }
        }
        .animation(.easeInOut, value: vm.filters.searchText.isEmpty)
    }
}

private struct ContentView: View {
    @Namespace private var namespace
    @EnvironmentObject private var vm: LibraryViewModel
    
    var body: some View {
        CollectionViewGrid(
            data: vm.items,
            content: { item in
                CardView(
                    namespace: namespace,
                    entry: item
                )
            },
            columns: 3,
            spacing: Constants.Spacing.minimal,
            showsScrollIndicator: false
        )
        .padding(.horizontal, Constants.Padding.regular)
    }
}

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
        .padding(.top, 12)
    }
}

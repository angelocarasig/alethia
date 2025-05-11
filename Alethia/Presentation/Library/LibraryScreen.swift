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
                SearchBar(searchText: $vm.filters.searchText).padding()
                
                CollectionSelectorView()
                
                ContentView()
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
}

private struct ContentView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @Namespace private var namespace
    
    var body: some View {
        CollectionViewGrid(
            data: vm.items,
            content: { CardView($0) },
            columns: 3,
            spacing: Constants.Spacing.minimal
        )
        .padding(.horizontal, Constants.Padding.regular)
    }
    
    @ViewBuilder
    private func CardView(_ entry: Entry) -> some View {
        NavigationLink {
            DetailsScreen(entry: entry, source: nil)
                .navigationTransition(.zoom(sourceID: entry.transitionId, in: namespace))
        } label: {
            EntryView(item: entry, lineLimit: 2)
                .matchedTransitionSource(id: entry.transitionId, in: namespace)
                .scrollTargetLayout()
                .unread(entry.unread ?? 0)
        }
        .padding(.top, 6)
    }
}

private struct UnreadBadgeModifier: ViewModifier {
    let unread: Int
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            
            if unread > 0 {
                let unreadAmount = "\(min(unread, 99))\(unread >= 99 ? "+" : "")"
                
                Text(unreadAmount)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
                    .background(.red)
                    .clipShape(.capsule)
                    .offset(y: -12)
            }
        }
    }
}

private extension View {
    func unread(_ count: Int) -> some View {
        self.modifier(UnreadBadgeModifier(unread: count))
    }
}

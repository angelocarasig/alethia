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
                    HStack(spacing: 16) {
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
                .padding(6)
                .background(Circle().fill(Color.red))
                .offset(x: 10, y: -10)
        }
    }
}

private struct ContentView: View {
    @EnvironmentObject private var vm: LibraryViewModel
    @Namespace private var namespace
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        ScrollView {
            Spacer().frame(height: 12)
            
            LazyVGrid(columns: columns) {
                ForEach(vm.items) { CardView($0) }
            }
            .padding(.horizontal, 8)
        }
        .onPullToRefresh {
            vm.refreshCollection()
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func CardView(_ entry: Entry) -> some View {
        NavigationLink {
            DetailsScreen(entry: entry)
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Capsule())
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

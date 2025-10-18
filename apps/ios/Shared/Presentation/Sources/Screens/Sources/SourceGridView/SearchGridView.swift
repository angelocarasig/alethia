//
//  SearchGridView.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain

struct SearchGridView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @State private var vm: SearchGridViewModel
    @Namespace private var namespace
    
    private let source: Source
    private let preset: SearchPreset
    private let gridColumnCount = 3
    
    var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: dimensions.spacing.minimal),
            count: gridColumnCount
        )
    }
    
    init(source: Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        
        self._vm = State(initialValue: SearchGridViewModel(
            source: source,
            preset: preset
        ))
    }
    
    var body: some View {
        ScrollView {
            if vm.entries.isEmpty && vm.isLoading {
                loadingView
            } else if vm.entries.isEmpty && !vm.isLoading {
                emptyView
            } else {
                gridContent
            }
        }
        .navigationTitle(preset.name)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            vm.refresh()
        }
        .task {
            vm.loadInitialData()
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") {
                vm.errorMessage = nil
            }
        } message: {
            if let error = vm.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - View Components
    
    private var gridContent: some View {
        LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
            ForEach(vm.entries, id: \.slug) { entry in
                SourceCard(
                    id: "\(preset.id)/\(entry.slug)",
                    entry: entry,
                    namespace: namespace
                )
                .onAppear {
                    if vm.shouldLoadMore(for: entry) {
                        vm.loadMore()
                    }
                }
            }
            
            // loading more indicator
            if vm.isLoadingMore {
                LoadingMoreIndicators()
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
    }
    
    private var loadingView: some View {
        LazyVGrid(columns: columns, spacing: dimensions.spacing.minimal) {
            ForEach(0..<12, id: \.self) { _ in
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                    .fill(theme.colors.foreground.opacity(0.05))
                    .aspectRatio(2/3, contentMode: .fit)
                    .shimmer()
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No manga found for this preset")
        )
        .frame(maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Loading More Indicators

private struct LoadingMoreIndicators: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        ForEach(0..<3, id: \.self) { index in
            RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                .fill(theme.colors.foreground.opacity(0.05))
                .aspectRatio(2/3, contentMode: .fit)
                .shimmer()
                .transition(
                    .opacity
                        .combined(with: .scale(scale: 0.9))
                        .animation(
                            theme.animations.spring.delay(Double(index) * 0.05)
                        )
                )
        }
    }
}

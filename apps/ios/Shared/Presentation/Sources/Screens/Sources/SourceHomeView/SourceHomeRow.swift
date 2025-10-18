//
//  SourceHomeRow.swift
//  Presentation
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import SwiftUI
import Composition
import Domain
import Kingfisher

@MainActor
@Observable
private final class SourceHomeRowViewModel {
    @ObservationIgnored
    private let searchWithPresetUseCase: SearchWithPresetUseCase
    @ObservationIgnored
    private let findMatchesUseCase: FindMatchesUseCase
    
    private let source: Domain.Source
    private let preset: SearchPreset
    
    // raw entries from search (no match state)
    @ObservationIgnored
    private(set) var rawEntries: [Entry] = []
    
    // enriched entries with match state populated
    private(set) var enrichedEntries: [Entry] = []
    
    private(set) var isLoading: Bool = false
    private(set) var error: Error?
    private(set) var hasAppeared: Bool = false
    
    @ObservationIgnored
    private var matchObservationTask: Task<Void, Never>?
    
    init(source: Domain.Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        self.searchWithPresetUseCase = Injector.makeSearchWithPresetUseCase()
        self.findMatchesUseCase = Injector.makeFindMatchesUseCase()
    }
    
    func search() {
        Task {
            isLoading = true
            error = nil
            
            do {
                let result = try await searchWithPresetUseCase.execute(source: source, preset: preset)
                rawEntries = result
                
                // start observing matches for raw entries
                startMatchObservation()
            } catch {
                self.error = error
            }
            
            isLoading = false
        }
    }
    
    func markAsAppeared() {
        hasAppeared = true
    }
    
    private func startMatchObservation() {
        // cancel any existing observation
        matchObservationTask?.cancel()
        
        // start new observation
        matchObservationTask = Task {
            for await result in findMatchesUseCase.execute(for: rawEntries) {
                if Task.isCancelled { break }
                
                switch result {
                case .success(let enriched):
                    self.enrichedEntries = enriched
                case .failure(let error):
                    // log error but don't fail the entire view
                    #if DEBUG
                    print("FindMatches error: \(error)")
                    #endif
                    // fallback to raw entries if matching fails
                    self.enrichedEntries = rawEntries
                }
            }
        }
    }
    
    deinit {
        matchObservationTask?.cancel()
    }
}

struct SourceHomeRow: View {
    @State private var vm: SourceHomeRowViewModel
    @Namespace private var namespace
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let source: Domain.Source
    let preset: SearchPreset
    
    init(source: Domain.Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        self.vm = SourceHomeRowViewModel(source: source, preset: preset)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            // section header
            NavigationLink(destination: SearchGridView(source: source, preset: preset)) {
                HStack(alignment: .center) {
                    Text(preset.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if vm.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .padding(.leading, dimensions.spacing.minimal)
                    }
                    
                    Spacer()
                    
                    if !vm.enrichedEntries.isEmpty {
                        Image(systemName: "chevron.forward")
                            .font(.caption)
                            .foregroundColor(theme.colors.foreground.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)
            
            // description if available
            if let description = preset.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                    .lineLimit(2)
            }
            
            // content
            if vm.isLoading && vm.enrichedEntries.isEmpty {
                LoadingPlaceholder()
            } else if let error = vm.error {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .frame(height: 180)
                .overlay(alignment: .topTrailing) {
                    Button("Retry") {
                        vm.search()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.accent)
                    .padding()
                }
            } else if vm.enrichedEntries.isEmpty && vm.hasAppeared {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No entries found for this preset")
                )
                .frame(height: 180)
            } else if !vm.hasAppeared {
                // placeholder before appearing
                LoadingPlaceholder()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Dimensions().spacing.minimal) {
                        ForEach(vm.enrichedEntries, id: \.slug) { entry in
                            SourceCard(
                                id: "\(preset.id)/\(entry.slug)",
                                entry: entry,
                                namespace: namespace
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            if !vm.hasAppeared {
                vm.markAsAppeared()
                vm.search()
            }
        }
        .animation(theme.animations.spring, value: vm.isLoading)
        .animation(theme.animations.spring, value: vm.enrichedEntries.count)
    }
}

// MARK: - Subviews

private extension SourceHomeRow {
    @ViewBuilder
    func LoadingPlaceholder() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: dimensions.spacing.regular) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: dimensions.cornerRadius.card)
                        .fill(theme.colors.foreground.opacity(0.05))
                        .frame(width: 125, height: 180)
                        .shimmer()
                }
            }
        }
    }
}

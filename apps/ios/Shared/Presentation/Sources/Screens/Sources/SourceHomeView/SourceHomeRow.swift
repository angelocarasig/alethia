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
    
    private let source: Domain.Source
    private let preset: SearchPreset
    
    private(set) var entries: [Entry] = []
    private(set) var isLoading: Bool = false
    private(set) var error: Error?
    
    init(source: Domain.Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        self.searchWithPresetUseCase = Injector.makeSearchWithPresetUseCase()
    }
    
    func search() {
        Task {
            isLoading = true
            error = nil
            
            do {
                let result = try await searchWithPresetUseCase.execute(source: source, preset: preset)
                entries = result
            } catch {
                self.error = error
            }
            
            isLoading = false
        }
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
                
                if !vm.entries.isEmpty {
                    Image(systemName: "chevron.forward")
                        .font(.caption)
                        .foregroundColor(theme.colors.foreground.opacity(0.5))
                }
            }
            .tappable {
                // navigate to full preset view
            }
            
            // description if available
            if let description = preset.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                    .lineLimit(2)
            }
            
            // content
            if vm.isLoading && vm.entries.isEmpty {
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
            } else if vm.entries.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No entries found for this preset")
                )
                .frame(height: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: Dimensions().spacing.minimal) {
                        ForEach(vm.entries, id: \.slug) { entry in
                            NavigationLink {
                                MangaDetailView(entry: entry)
                            } label: {
                                EntryCard(entry: entry, lineLimit: 2)
                                    .frame(width: 125)
                                    .id("\(preset.id)/\(entry.slug)")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if vm.entries.isEmpty && !vm.isLoading {
                vm.search()
            }
        }
        .animation(theme.animations.spring, value: vm.isLoading)
        .animation(theme.animations.spring, value: vm.entries.count)
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

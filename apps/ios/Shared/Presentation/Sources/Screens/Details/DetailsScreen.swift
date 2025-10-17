//
//  DetailsScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Domain
import Composition

fileprivate let BACKGROUND_GRADIENT_BREAKPOINT: CGFloat = 600

struct DetailsScreen: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let entry: Entry
    
    @State private var vm: MangaDetailViewModel
    
    init(entry: Entry) {
        self.entry = entry
        self._vm = State(initialValue: MangaDetailViewModel(entry: entry))
    }
    
    var body: some View {
        contentView
            .task {
                if vm.manga.isEmpty && !vm.isLoading {
                    vm.loadManga()
                }
            }
            .environment(vm)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if vm.isLoading {
            Spinner(size: .large)
        } else if let error = vm.error {
            ErrorView(error: error)
        } else if let manga = vm.manga.first {
            DetailContentView(manga: manga)
        } else {
            EmptyStateView()
        }
    }
}

// MARK: - Error View
extension DetailsScreen {
    @ViewBuilder
    private func ErrorView(error: Error) -> some View {
        ContentUnavailableView {
            Label("An Error Occurred", systemImage: "exclamationmark.triangle.fill")
        } description: {
            VStack(spacing: dimensions.spacing.large) {
                Text("Something went wrong loading details of \(entry.title)...")
                    .font(.headline)
                    .fontWeight(.regular)
                
                Text(error.localizedDescription)
                    .fontDesign(.monospaced)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, dimensions.padding.regular)
        } actions: {
            Button("Retry") {
                vm.loadManga()
            }
        }
    }
}

// MARK: - Empty State View
extension DetailsScreen {
    @ViewBuilder
    private func EmptyStateView() -> some View {
        ContentUnavailableView {
            Label("No Details Found", systemImage: "book.closed")
        } description: {
            Text("Could not find any details for this manga.")
        } actions: {
            Button("Retry") {
                vm.loadManga()
            }
        }
    }
}

// MARK: - Detail Content View
extension DetailsScreen {
    @ViewBuilder
    private func DetailContentView(manga: Manga) -> some View {
        ZStack {
            BackdropView(backdrop: manga.covers.firstOrDefault)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
                    Spacer().frame(height: 200)
                    
                    HeaderView(
                        cover: manga.covers.firstOrDefault,
                        title: manga.title,
                        alternativeTitles: manga.alternativeTitles,
                        authors: manga.authors,
                        covers: manga.covers
                    )
                    
                    ActionButtonsView(manga: manga)
                    
                    SynopsisView(synopsis: manga.synopsis)
                    
                    TagsView(tags: manga.tags)
                    
                    Divider()
                    
                    RelationalView(manga: manga)
                    
                    Divider()
                    
                    if let origin = manga.origins.first {
                        MetadataView(
                            classification: origin.classification,
                            status: origin.status,
                            addedAt: manga.addedAt,
                            updatedAt: manga.updatedAt,
                            lastFetchedAt: manga.lastFetchedAt,
                            lastReadAt: manga.lastReadAt
                        )
                        
                        Divider()
                    }
                    
                    ChaptersSummaryView(chapters: manga.chapters, sources: manga.origins.count)
                }
                .padding(.horizontal, dimensions.padding.regular)
                .background(BackgroundGradientView())
            }
        }
    }
}

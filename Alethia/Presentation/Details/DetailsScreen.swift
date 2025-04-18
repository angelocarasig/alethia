//
//  DetailsScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct DetailsScreen: View {
    @StateObject var vm = DetailsViewModel()
    
    var body: some View {
        Group {
            if case .empty = vm.state {
                EmptyView()
            }
            else if case .error(let error) = vm.state {
                ErrorView(error: error)
            }
            else {
                DetailContentView()
            }
        }
        .environmentObject(vm)
        .task {
            vm.bind()
        }
    }
}

private struct EmptyView: View {
    var body: some View {
        ContentUnavailableView(
            "No Details Found",
            systemImage: "book.closed",
            description: Text("The provided manga details did not match any records")
        )
    }
}

private struct ErrorView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    let error: Error
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            
            Text("Error loading details")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                vm.bind()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct DetailContentView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    typealias Tabs = DetailsViewModel.Tabs
    
    var body: some View {
        ZStack {
            BackdropView(cover: vm.details?.covers.first)
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Spacer().frame(height: geometry.size.height / 3)
                        
                        if let details = vm.details {
                            HeaderView(
                                title: details.manga.title,
                                authors: details.authors
                            )
                            
                            ActionButtonsView()

                            SynopsisView(synopsis: details.manga.synopsis)
                            
                            TagsView(tags: details.tags)
                            
                            Divider()
                            
                            TrackingView()
                            
                            Divider()
                            
                            SourcesView()
                            
                            Divider()
                            
                            CollectionsView()
                            
                            ChapterListView()
                        }
                        else {
                            PlaceholderView(geometry: geometry)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 12)
                    .background(BackgroundGradientView())
                }
            }
        }
    }
}

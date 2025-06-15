//
//  LibraryScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 15/6/2025.
//

import SwiftUI
import Core
import Domain
import Composition

fileprivate enum Constants {
    static let padding: CGFloat = 12
    static let spacing: CGFloat = 4
}

public struct LibraryScreen<ViewModel: LibraryViewModel>: View {
    @StateObject private var vm: ViewModel
    @State private var showFilters: Bool = false
    
    public init(vm: ViewModel) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                        }
                    }
                }
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        VStack(spacing: 0) {
            searchBar
            
            ZStack {
                switch vm.state {
                case .idle:
                    EmptyView()
                case .loading:
                    loadingView
                case .loaded(let entries):
                    if entries.isEmpty {
                        emptyView
                    } else {
                        libraryGrid(entries: entries)
                    }
                case .error(let error):
                    errorView(error)
                case .empty:
                    emptyView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Subviews
    private var searchBar: some View {
        TextField("Search", text: .constant(""))
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .controlSize(.large)
            Text("Loading library...")
                .padding()
        }
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .padding()
            
            Text("Error loading library")
                .font(.title3)
                .bold()
                .padding(.bottom, 4)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                // Reactive approach will reload when filters/collectionId change
                // This forces a reload by toggling and immediately resetting the collection ID
                let currentId = vm.collectionId
                vm.collectionId = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    vm.collectionId = currentId
                }
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "Nothing found...",
            image: "books.vertical",
            description: Text("Add manga to your library to see them here.")
        )
    }
    
    private func libraryGrid(entries: [Domain.Models.Virtual.Entry]) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: Constants.spacing),
            GridItem(.flexible(), spacing: Constants.spacing),
            GridItem(.flexible(), spacing: Constants.spacing)
        ]
        
        return ScrollView {
            LazyVGrid(columns: columns, spacing: Constants.spacing) {
                ForEach(entries, id: \.mangaId) { entry in
                    NavigationLink {
                        Text("Details coming soon")
                    } label: {
                        EntryItemView(entry: entry)
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Constants.padding)
        }
    }
}

// MARK: - Entry Item View
struct EntryItemView: View {
    let entry: Domain.Models.Virtual.Entry
    
    var body: some View {
        VStack(alignment: .leading) {
            // Placeholder for cover image
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay {
                    AsyncImage(url: URL(string: entry.cover)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "book.closed")
                                .font(.largeTitle)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .aspectRatio(2/3, contentMode: .fit)
            
            Text(entry.title)
                .font(.caption)
                .lineLimit(2)
                .padding(.top, 4)
        }
    }
}

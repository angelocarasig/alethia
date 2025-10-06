//
//  MangaDetailView.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import SwiftUI
import Composition
import Domain
import Kingfisher

@MainActor
@Observable
private final class MangaDetailViewModel {
    @ObservationIgnored
    private let getMangaDetailsUseCase: GetMangaDetailsUseCase
    
    private let entry: Entry
    
    private(set) var manga: [Manga] = []
    private(set) var isLoading: Bool = false
    private(set) var error: Error?
    
    init(entry: Entry) {
        self.entry = entry
        self.getMangaDetailsUseCase = Injector.makeGetMangaDetailsUseCase()
    }
    
    func loadManga() {
        Task {
            isLoading = true
            error = nil
            
            for await result in getMangaDetailsUseCase.execute(entry: entry) {
                switch result {
                case .success(let mangaList):
                    manga = mangaList
                    isLoading = false
                case .failure(let err):
                    error = err
                    isLoading = false
                }
            }
        }
    }
}

struct MangaDetailView: View {
    @State private var vm: MangaDetailViewModel
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
        self.vm = MangaDetailViewModel(entry: entry)
    }
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.error {
                ContentUnavailableView(
                    "Failed to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
                .overlay(alignment: .bottom) {
                    Button("Retry") {
                        vm.loadManga()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } else if let manga = vm.manga.first {
                ScrollView {
                    VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                        // title
                        Text(manga.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // chapter count
                        Text("\(manga.chapters.count) Chapters")
                            .font(.caption)
                            .foregroundColor(theme.colors.foreground.opacity(0.6))
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Manga Found",
                    systemImage: "book.closed",
                    description: Text("Could not find manga for this entry")
                )
            }
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm.manga.isEmpty && !vm.isLoading {
                vm.loadManga()
            }
        }
    }
}

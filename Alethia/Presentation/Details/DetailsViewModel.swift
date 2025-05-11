//
//  DetailsViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation
import SwiftUI
import Combine

final class DetailsViewModel: ObservableObject {
    @Published var options: [Detail] = []
    
    @Published var details: Detail? = nil
    @Published var error: Error? = nil
    @Published var loading: Bool = false
    
    var sourcePresent: Bool {
        return self.details != nil &&
        self.details!.manga.inLibrary &&
        self.details!.origins.contains { entry.fetchUrl?.decodeUri.contains($0.slug.decodeUri) ?? false }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let getMangaDetailUseCase: GetMangaDetailUseCase
    private let toggleMangaInLibraryUseCase: ToggleMangaInLibraryUseCase
    
    var entry: Entry
    
    init(entry: Entry) {
        self.entry = entry
        self.getMangaDetailUseCase = DependencyInjector.shared.makeGetMangaDetailUseCase()
        self.toggleMangaInLibraryUseCase = DependencyInjector.shared.makeToggleMangaInLibraryUseCase()
    }
    
    deinit {
        for cancellable in cancellables {
            cancellable.cancel()
        }
    }
    
    func bind() {
        loading = true
        error = nil
        
        getMangaDetailUseCase.execute(entry: entry)
          .receive(on: DispatchQueue.main)
          .sink { [weak self] completion in
              if case .failure(let error) = completion {
                  self?.error = error
              }
          } receiveValue: { [weak self] detailArray in
              guard let self = self else { return }
              self.loading = false

              if detailArray.count > 1 {
                  self.details = nil
                  self.options = detailArray
              }
              else if let first = detailArray.first {
                  self.options = []
                  
                  withAnimation {
                      self.details = first
                  }
              }
              else {
                  self.options = []
                  self.details = nil
              }
          }
          .store(in: &cancellables)
    }
    
    func pickOption(option: Detail) {
        // TODO: Related to when multiple matches are found by title for a manga
        // Should only occur in sources tab - 
        // should update the entry object with the selected option's mangaId and re-bind for proper observation
        self.entry = Entry(
            mangaId: option.manga.id!,
            sourceId: entry.sourceId,
            title: entry.title,
            cover: entry.cover,
            fetchUrl: entry.fetchUrl,
            unread: entry.unread
        )
        
        bind()
    }
    
    func toggleInLibrary() -> Void {
        do {
            guard let details = details,
                  let mangaId = details.manga.id
            else { return }
            
            try toggleMangaInLibraryUseCase.execute(
                mangaId: mangaId,
                newValue: !details.manga.inLibrary
            )
        }
        catch {
            print("Error: \(error)")
        }
    }
}

// MARK: State

extension DetailsViewModel {
    enum State {
        case loading
        case conflict
        case success(Detail)
        case error(Error)
        case empty
    }
    
    var state: State {
        if loading {
            return .loading
        } else if !options.isEmpty {
            return .conflict
        }
        else if let details {
            return .success(details)
        } else if let error {
            return .error(error)
        } else {
            return .empty
        }
    }
}

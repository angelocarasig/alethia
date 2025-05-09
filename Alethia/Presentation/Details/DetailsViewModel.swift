//
//  DetailsViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation
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
    
    func bind() {
        loading = true
        error = nil
        
        getMangaDetailUseCase.execute(entry: self.entry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { [weak self] detail in
                self?.options = []
                
                // When multiple entries are found the proper one needs to be picked
                if detail.count > 1 {
                    self?.options = detail
                }
                else if detail.isEmpty {
                    self?.details = nil
                }
                else {
                    self?.details = detail.first!
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

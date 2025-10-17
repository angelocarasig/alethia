//
//  MangaDetailViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import Foundation
import Domain
import Composition

@MainActor
@Observable
final class MangaDetailViewModel {
    @ObservationIgnored
    private let getMangaDetailsUseCase: GetMangaDetailsUseCase
    
    @ObservationIgnored
    private let addMangaToLibraryUseCase: AddMangaToLibraryUseCase
    
    @ObservationIgnored
    private let removeMangaFromLibraryUseCase: RemoveMangaFromLibraryUseCase
    
    private let entry: Entry
    
    private(set) var manga: [Manga] = []
    private(set) var isLoading: Bool = false
    private(set) var error: Error?
    
    // library state
    private(set) var isAddingToLibrary: Bool = false
    private(set) var isRemovingFromLibrary: Bool = false
    
    init(entry: Entry) {
        self.entry = entry
        self.getMangaDetailsUseCase = Injector.makeGetMangaDetailsUseCase()
        self.addMangaToLibraryUseCase = Injector.makeAddMangaToLibraryUseCase()
        self.removeMangaFromLibraryUseCase = Injector.makeRemoveMangaFromLibraryUseCase()
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
    
    func addToLibrary(mangaId: Int64) {
        guard !isAddingToLibrary else { return }
        
        Task {
            isAddingToLibrary = true
            
            do {
                try await addMangaToLibraryUseCase.execute(mangaId: mangaId)
            } catch {
                // error silently handled - UI will update from stream
                print("Failed to add to library: \(error.localizedDescription)")
            }
            
            isAddingToLibrary = false
        }
    }
    
    func removeFromLibrary(mangaId: Int64) {
        guard !isRemovingFromLibrary else { return }
        
        Task {
            isRemovingFromLibrary = true
            
            do {
                try await removeMangaFromLibraryUseCase.execute(mangaId: mangaId)
            } catch {
                // error silently handled - UI will update from stream
                print("Failed to remove from library: \(error.localizedDescription)")
            }
            
            isRemovingFromLibrary = false
        }
    }
}

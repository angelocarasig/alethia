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
    
    private var entry: Entry
    
    private(set) var state: ViewState = .loading
    
    // library state
    private(set) var isAddingToLibrary: Bool = false
    private(set) var isRemovingFromLibrary: Bool = false
    
    enum ViewState {
        case loading
        case error(Error)
        case disambiguation([Manga])
        case content(Manga)
        case empty
    }
    
    init(entry: Entry) {
        self.entry = entry
        self.getMangaDetailsUseCase = Injector.makeGetMangaDetailsUseCase()
        self.addMangaToLibraryUseCase = Injector.makeAddMangaToLibraryUseCase()
        self.removeMangaFromLibraryUseCase = Injector.makeRemoveMangaFromLibraryUseCase()
    }
    
    func loadManga() {
        Task {
            state = .loading
            
            for await result in getMangaDetailsUseCase.execute(entry: entry) {
                switch result {
                case .success(let mangaList):
                    handleMangaList(mangaList)
                case .failure(let error):
                    state = .error(error)
                }
            }
        }
    }
    
    func selectManga(_ manga: Manga) {
        // update entry with the selected manga id
        entry = Entry(
            mangaId: manga.id,
            sourceId: entry.sourceId,
            slug: entry.slug,
            title: entry.title,
            cover: entry.cover,
            state: entry.state,
            unread: entry.unread
        )
        
        // re-fetch with specific manga id
        loadManga()
    }
    
    func createNewManga() {
        #warning("implement create new manga flow")
        fatalError("create new manga not yet implemented")
    }
    
    func addToLibrary(mangaId: Int64) {
        guard !isAddingToLibrary else { return }
        
        Task {
            isAddingToLibrary = true
            
            do {
                try await addMangaToLibraryUseCase.execute(mangaId: mangaId)
            } catch {
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
                print("Failed to remove from library: \(error.localizedDescription)")
            }
            
            isRemovingFromLibrary = false
        }
    }
    
    private func handleMangaList(_ mangaList: [Manga]) {
        if mangaList.isEmpty {
            state = .empty
        } else if mangaList.count == 1 {
            state = .content(mangaList[0])
        } else {
            state = .disambiguation(mangaList)
        }
    }
}

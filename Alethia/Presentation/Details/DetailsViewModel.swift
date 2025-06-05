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
    // MARK: - Published Properties
    @Published private(set) var state: ViewState = .loading
    @Published private(set) var addingOrigin: Bool = false // loading state while an origin is being added
    @Published var confirmationRequest: ConfirmationRequest? = nil
    @Published var collections: [CollectionExtended] = []
    
    // MARK: - Properties
    private(set) var entry: Entry
    private(set) var resolvedOrientation: Orientation?
    private var context: Source?
    private var options: [Detail] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Use Cases
    private let getMangaDetailUseCase: GetMangaDetailUseCase
    private let resolveMangaOrientationUseCase: ResolveMangaOrientationUseCase
    private let addMangaToLibraryUseCase: AddMangaToLibraryUseCase
    private let removeMangaFromLibraryUseCase: RemoveMangaFromLibraryUseCase
    private let addMangaOriginUseCase: AddMangaOriginUseCase
    private let markAllChaptersUseCase: MarkAllChaptersUseCase
    private let updateMangaCoverUseCase: UpdateMangaCoverUseCase
    
    // MARK: - Collections
    private let getAllCollectionsUseCase: GetAllCollectionsUseCase
    private let addCollectionUseCase: AddCollectionUseCase
    
    // MARK: - Downloading
    private let downloadChapterUseCase: DownloadChapterUseCase
    
    
    // MARK: - Initialization
    init(entry: Entry, context: Source?) {
        self.entry = entry
        self.context = context
        
        let injector = DependencyInjector.shared
        self.getMangaDetailUseCase = injector.makeGetMangaDetailUseCase()
        self.resolveMangaOrientationUseCase = injector.makeResolveMangaOrientationUseCase()
        self.addMangaToLibraryUseCase = injector.makeAddMangaToLibraryUseCase()
        self.removeMangaFromLibraryUseCase = injector.makeRemoveMangaFromLibraryUseCase()
        self.addMangaOriginUseCase = injector.makeAddMangaOriginUseCase()
        self.markAllChaptersUseCase = injector.makeMarkAllChaptersUseCase()
        self.updateMangaCoverUseCase = injector.makeUpdateMangaCoverUseCase()
        
        self.getAllCollectionsUseCase = injector.makeGetAllCollectionsUseCase()
        self.addCollectionUseCase = injector.makeAddCollectionUseCase()
        
        self.downloadChapterUseCase = injector.makeDownloadChapterUseCase()
        
        self.observeMetadataRefreshState()
    }
}

// MARK: - Computed Properties
extension DetailsViewModel {
    var sourcePresent: Bool {
        guard case let .success(details) = state,
              details.manga.inLibrary else { return false }
        
        return details.origins.contains {
            entry.fetchUrl?.decodeUri.contains($0.origin.slug.decodeUri) ?? false
        }
    }
    
    var details: Detail? {
        if case let .success(details) = state {
            return details
        }
        return nil
    }
    
    var inLibrary: Bool {
        details?.manga.inLibrary ?? false
    }
    
    var activeCover: Cover? {
        details?.covers.first(where: { $0.active })
    }
    
    var chapters: [ChapterExtended] {
        details?.chapters ?? []
    }
    
    var stateIdentifier: String {
        switch state {
        case .loading: return "loading"
        case .empty: return "empty"
        case .error: return "error"
        case .success: return "success"
        case .refreshing: return "refreshing"
        case .conflict: return "conflict"
        }
    }
}

// MARK: - Data Loading
extension DetailsViewModel {
    func loadDetails() {
        state = .loading
        
        // just load collections here
        loadCollections()
        
        getMangaDetailUseCase.execute(entry: entry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    withAnimation {
                        self?.state = .error(error)
                    }
                }
            } receiveValue: { [weak self] received in
                guard let self = self else { return }
                
                withAnimation {
                    if received.count > 1 {
                        self.options = received
                        self.state = .conflict(received)
                    } else if let first = received.first {
                        self.options = []
                        print("Details Updated!")
                        self.state = .success(first)
                        
                        // MARK: - update internal entry's mangaId for usage with metadata refreshes
                        self.entry.mangaId = first.manga.id
                        
                        self.resolvedOrientation = self.resolveMangaOrientationUseCase.execute(detail: first)
                    } else {
                        self.options = []
                        self.state = .empty
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func loadCollections() {
        getAllCollectionsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] collections in
                self?.collections = collections
            }
            .store(in: &cancellables)
    }
}

// MARK: - Conflict Resolution
extension DetailsViewModel {
    func requestConfirmation(for option: Detail) {
        withAnimation {
            confirmationRequest = ConfirmationRequest(
                title: "Confirm Selection",
                message: "You will be viewing '\(option.manga.title)'",
                detail: option
            )
        }
    }
    
    func confirmSelection() {
        guard let request = confirmationRequest,
              let mangaId = request.detail.manga.id,
              let source = context,
              let sourceId = source.id else {
            withAnimation {
                confirmationRequest = nil
                state = .error(ApplicationError.internalError)
            }
            return
        }
        
        self.entry = Entry(
            mangaId: mangaId,
            sourceId: sourceId,
            title: entry.title,
            cover: entry.cover,
            fetchUrl: entry.fetchUrl,
            unread: entry.unread
        )
        
        withAnimation {
            confirmationRequest = nil
        }
        
        loadDetails()
    }
    
    func cancelConfirmation() {
        withAnimation {
            confirmationRequest = nil
        }
    }
}

// MARK: - Use-Cases | Library Actions
extension DetailsViewModel {
    func refreshMetadata() {
        QueueProvider.shared.refreshMetadata(entry)
    }
    
    func addToLibrary(collections: [Int64], onSuccess: (() -> Void)? = nil) {
        guard case let .success(details) = state,
              let mangaId = details.manga.id,
              !details.manga.inLibrary else { return }
        
        do {
            // Add to library with no collections (empty array)
            try addMangaToLibraryUseCase.execute(mangaId: mangaId, collections: collections)
            onSuccess?()
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func removeFromLibrary() {
        guard case let .success(details) = state,
              let mangaId = details.manga.id,
              details.manga.inLibrary else { return }
        
        do {
            // Remove from library (automatically removes from all collections)
            try removeMangaFromLibraryUseCase.execute(mangaId: mangaId)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    @MainActor
    func addOrigin() async -> Void {
        guard
            !sourcePresent,
            let details = details,
            let mangaId = details.manga.id
        else { return }
        defer {
            withAnimation {
                addingOrigin = false
            }
        }
        
        withAnimation {
            addingOrigin = true
        }
        
        do {
            try await addMangaOriginUseCase.execute(entry: self.entry, mangaId: mangaId)
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func markChapter(asRead: Bool, for chapter: ChapterExtended) {
        do {
            try markAllChaptersUseCase.execute(chapters: [chapter.chapter], asRead: asRead)
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func markAllChapters(asRead: Bool) {
        guard !chapters.isEmpty else { return }
        
        do {
            try markAllChaptersUseCase.execute(
                chapters: chapters.map { $0.chapter },
                asRead: asRead
            )
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func markAllChaptersAbove(from chapter: ChapterExtended, asRead: Bool) {
        guard !chapters.isEmpty else { return }
        
        // Find all chapters with number >= target chapter number
        let chaptersInRange = chapters
            .map { $0.chapter }
            .filter { $0.number >= chapter.chapter.number }
        
        guard !chaptersInRange.isEmpty else { return }
        
        markAllChaptersInRange(chapters: chaptersInRange, asRead: asRead)
    }
    
    func markAllChaptersBelow(from chapter: ChapterExtended, asRead: Bool) {
        guard !chapters.isEmpty else { return }
        
        // Find all chapters with number <= target chapter number
        let chaptersInRange = chapters
            .map { $0.chapter }
            .filter { $0.number <= chapter.chapter.number }
        
        guard !chaptersInRange.isEmpty else { return }
        
        markAllChaptersInRange(chapters: chaptersInRange, asRead: asRead)
    }
    
    /// chapters passed should be calculated
    private func markAllChaptersInRange(chapters: [Chapter], asRead: Bool) {
        do {
            try markAllChaptersUseCase.execute(chapters: chapters, asRead: asRead)
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func updateMangaCover(_ cover: Cover) {
        guard let mangaId = details?.manga.id,
              let coverId = cover.id else { return }
        
        do {
            try updateMangaCoverUseCase.execute(mangaId: mangaId, coverId: coverId)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func addCollection(name: String, color: String, icon: String) throws -> Void {
        try addCollectionUseCase.execute(name: name, color: color, icon: icon)
    }
}

// MARK: - Downloads
extension DetailsViewModel {
    func downloadChapter(_ chapter: Chapter) {
        QueueProvider.shared.downloadChapter(chapter, mangaId: details?.manga.id)
    }
}

// MARK: - Observation
extension DetailsViewModel {
    private func observeMetadataRefreshState() {
        QueueProvider.shared.$operations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] operations in
                guard let self = self else { return }
                
                // Check if there's an ongoing metadata refresh operation for this manga
                if let operation = operations[entry.queueOperationId] {
                    // skip if not metadata refresh
                    guard case .metadataRefresh = operation.type else { return }
                    
                    switch operation.state {
                    case .pending:
                        // Start refreshing state with 0 progress
                        if case .success(let currentDetails) = self.state {
                            withAnimation {
                                self.state = .refreshing(currentDetails, progress: 0.0)
                            }
                        }
                    case .ongoing(let progress):
                        // Update progress while refreshing
                        if case .refreshing(let currentDetails, _) = self.state {
                            withAnimation {
                                self.state = .refreshing(currentDetails, progress: progress)
                            }
                        }
                    case .completed:
                        // Refresh completed - reload details to get updated data
                        self.loadDetails()
                    case .failed(let error):
                        // Refresh failed
                        withAnimation {
                            self.state = .error(error)
                        }
                    case .cancelled:
                        // Refresh cancelled - go back to success state
                        if case .refreshing(let currentDetails, _) = self.state {
                            withAnimation {
                                self.state = .success(currentDetails)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - View State
extension DetailsViewModel {
    enum ViewState {
        case loading
        case conflict([Detail])
        case success(Detail)
        case error(Error)
        case refreshing(Detail, progress: Double)
        case empty
    }
    
    struct ConfirmationRequest {
        let title: String
        let message: String
        let detail: Detail
    }
}

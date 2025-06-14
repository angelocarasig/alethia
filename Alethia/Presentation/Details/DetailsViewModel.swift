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
    @Published var collections: [CollectionExtended] = []
    @Published var confirmationRequest: ConfirmationRequest? = nil
    
    // MARK: - Flags
    // indicates when an origin is being added (i.e. show spinners)
    @Published private(set) var isAddingOrigin: Bool = false
    
    // when we init this view while a metadata refresh is ongoing we need to block view until its been fully resolved
    private var waitingForMetadataRefresh: Bool = false
    
    // MARK: - Private Properties
    private(set) var entry: Entry
    private(set) var resolvedOrientation: Orientation?
    private var context: Source?
    private var options: [Detail] = []
    
    // MARK: - Use Cases
    private var cancellables = Set<AnyCancellable>()
    
    // The usual stuff
    private let getMangaDetailUseCase: GetMangaDetailUseCase
    private let resolveMangaOrientationUseCase: ResolveMangaOrientationUseCase
    
    // CRUD
    private let addMangaToLibraryUseCase: AddMangaToLibraryUseCase
    private let removeMangaFromLibraryUseCase: RemoveMangaFromLibraryUseCase
    private let addMangaOriginUseCase: AddMangaOriginUseCase
    private let markAllChaptersUseCase: MarkAllChaptersUseCase
    private let updateMangaCoverUseCase: UpdateMangaCoverUseCase
    
    // Collections
    private let getAllCollectionsUseCase: GetAllCollectionsUseCase
    private let addCollectionUseCase: AddCollectionUseCase
    private let updateMangaCollectionsUseCase: UpdateMangaCollectionsUseCase
    private let updateCollectionUseCase: UpdateCollectionUseCase
    private let deleteCollectionUseCase: DeleteCollectionUseCase
    
    // Priority management
    private let updateOriginPriorityUseCase: UpdateOriginPriorityUseCase
    private let updateScanlatorPriorityUseCase: UpdateScanlatorPriorityUseCase
    private let updateMangaSettingsUseCase: UpdateMangaSettingsUseCase
    
    // Downloads
    private let downloadChapterUseCase: DownloadChapterUseCase
    private let removeChapterDownloadUseCase: RemoveChapterDownloadUseCase
    private let removeAllChapterDownloadsUseCase: RemoveAllChapterDownloadsUseCase
    
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
        
        // Collection operations
        self.getAllCollectionsUseCase = injector.makeGetAllCollectionsUseCase()
        self.addCollectionUseCase = injector.makeAddCollectionUseCase()
        self.updateMangaCollectionsUseCase = injector.makeUpdateMangaCollectionsUseCase()
        self.updateCollectionUseCase = injector.makeUpdateCollectionUseCase()
        self.deleteCollectionUseCase = injector.makeDeleteCollectionUseCase()
        
        // Priority operations
        self.updateOriginPriorityUseCase = injector.makeUpdateOriginPriorityUseCase()
        self.updateScanlatorPriorityUseCase = injector.makeUpdateScanlatorPriorityUseCase()
        self.updateMangaSettingsUseCase = injector.makeUpdateMangaSettingsUseCase()
        
        // Download operations
        self.downloadChapterUseCase = injector.makeDownloadChapterUseCase()
        self.removeChapterDownloadUseCase = injector.makeRemoveChapterDownloadUseCase()
        self.removeAllChapterDownloadsUseCase = injector.makeRemoveAllChapterDownloadsUseCase()
        
        // Start observing metadata refresh state
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
        // Check if we're waiting for an active refresh to complete
        guard !waitingForMetadataRefresh else {
            print("🟨 Waiting for active refresh to complete before loading")
            return
        }
        
        state = .loading
        
        // Load collections in parallel
        loadCollections()
        
        // Execute detail fetch
        getMangaDetailUseCase.execute(entry: entry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    withAnimation {
                        print("Failed to load details: \(error)")
                        self?.state = .error(error)
                    }
                }
            } receiveValue: { [weak self] received in
                guard let self = self else { return }
                
                withAnimation {
                    if received.count > 1 {
                        // Multiple matches found
                        self.options = received
                        self.state = .conflict(received)
                    } else if let first = received.first {
                        // Single match found
                        self.options = []
                        print("Details Updated!")
                        self.state = .success(first)
                        
                        // Update entry's mangaId for future operations
                        self.entry.mangaId = first.manga.id
                        
                        // Resolve reading orientation
                        self.resolvedOrientation = self.resolveMangaOrientationUseCase.execute(detail: first)
                    } else {
                        // No matches found
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
        
        // Create new entry with resolved manga ID
        self.entry = Entry(
            mangaId: mangaId,
            sourceId: sourceId,
            title: entry.title,
            // TODO: Confirm
            slug: entry.slug,
            cover: entry.cover,
            fetchUrl: entry.fetchUrl,
            unread: entry.unread
        )
        
        withAnimation {
            confirmationRequest = nil
        }
        
        // Reload with resolved entry
        loadDetails()
    }
    
    func cancelConfirmation() {
        withAnimation {
            confirmationRequest = nil
        }
    }
}

// MARK: - Library Operations

extension DetailsViewModel {
    func refreshMetadata() {
        QueueProvider.shared.refreshMetadata(entry)
    }
    
    func addToLibrary(collections: [Int64], onSuccess: (() -> Void)? = nil) {
        guard case let .success(details) = state,
              let mangaId = details.manga.id,
              !details.manga.inLibrary else { return }
        
        do {
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
            try removeMangaFromLibraryUseCase.execute(mangaId: mangaId)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    @MainActor
    func addOrigin() async -> Void {
        guard !sourcePresent,
              let details = details,
              let mangaId = details.manga.id else { return }
        
        defer {
            withAnimation {
                isAddingOrigin = false
            }
        }
        
        withAnimation {
            isAddingOrigin = true
        }
        
        do {
            try await addMangaOriginUseCase.execute(entry: self.entry, mangaId: mangaId)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
}

// MARK: - Chapter Operations

extension DetailsViewModel {
    func markChapter(asRead: Bool, for chapter: ChapterExtended) {
        do {
            try markAllChaptersUseCase.execute(chapters: [chapter.chapter], asRead: asRead)
        } catch {
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
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func markAllChaptersAbove(from chapter: ChapterExtended, asRead: Bool) {
        guard !chapters.isEmpty else { return }
        
        let chaptersInRange = chapters
            .map { $0.chapter }
            .filter { $0.number >= chapter.chapter.number }
        
        guard !chaptersInRange.isEmpty else { return }
        
        markAllChaptersInRange(chapters: chaptersInRange, asRead: asRead)
    }
    
    func markAllChaptersBelow(from chapter: ChapterExtended, asRead: Bool) {
        guard !chapters.isEmpty else { return }
        
        let chaptersInRange = chapters
            .map { $0.chapter }
            .filter { $0.number <= chapter.chapter.number }
        
        guard !chaptersInRange.isEmpty else { return }
        
        markAllChaptersInRange(chapters: chaptersInRange, asRead: asRead)
    }
    
    private func markAllChaptersInRange(chapters: [Chapter], asRead: Bool) {
        do {
            try markAllChaptersUseCase.execute(chapters: chapters, asRead: asRead)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func downloadChapter(_ chapter: Chapter) {
        QueueProvider.shared.downloadChapter(chapter, mangaId: details?.manga.id)
    }
    
    func downloadAllChapters() {
        // reversed to queue from first chapter
        for chapter in self.chapters.reversed() {
            // only queue non-downloaded chapters
            guard !chapter.chapter.downloaded else {
                continue
            }
            
            self.downloadChapter(chapter.chapter)
        }
    }
    
    func deleteChapter(_ chapter: Chapter) {
        do {
            try removeChapterDownloadUseCase.execute(chapter: chapter)
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func deleteAllChapters() {
        guard let mangaId = details?.manga.id else { return }
        
        do {
            try removeAllChapterDownloadsUseCase.execute(mangaId: mangaId)
        }
        catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
}

// MARK: - Cover & Collection Operations

extension DetailsViewModel {
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
    
    func updateMangaCollections(_ collections: [Int64]) throws -> Void {
        guard let mangaId = details?.manga.id else {
            throw ApplicationError.internalError
        }
        
        try updateMangaCollectionsUseCase.execute(mangaId: mangaId, collectionIds: collections)
    }
    
    func updateCollection(collectionId: Int64, newName: String, newIcon: String, newColor: String) throws -> Void {
        try updateCollectionUseCase.execute(collectionId: collectionId, newName: newName, newIcon: newIcon, newColor: newColor)
    }
    
    func deleteCollection(collectionId: Int64) throws -> Void {
        try deleteCollectionUseCase.execute(collectionId: collectionId)
    }
}

// MARK: - Priority Oeperations
extension DetailsViewModel {
    func updateOriginPriorities(_ reorderedOrigins: [OriginExtended]) {
        guard let mangaId = details?.manga.id else { return }
        
        // Get ALL origins for this manga from current state
        guard let allOrigins = details?.origins else { return }
        
        // Create a mapping of the reordered priorities
        var originPriorityMap: [Int64: Int] = [:]
        for (index, origin) in reorderedOrigins.enumerated() {
            if let originId = origin.origin.id {
                originPriorityMap[originId] = index
            }
        }
        
        // Build complete priority list including unchanged origins
        let newPriorities = allOrigins.compactMap { origin -> (originId: Int64, priority: Int)? in
            guard let originId = origin.origin.id else { return nil }
            
            if let newPriority = originPriorityMap[originId] {
                return (originId: originId, priority: newPriority)
            } else {
                // Keep original priority for unchanged origins
                return (originId: originId, priority: origin.origin.priority)
            }
        }
        
        do {
            try updateOriginPriorityUseCase.execute(mangaId: mangaId, newPriorities: newPriorities)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func updateScanlatorPriorities(_ reorderedScanlators: [ScanlatorExtended], for originId: Int64) {
        // Get ALL scanlators for this origin from current state
        guard let allScanlators = details?.scanlators.filter({ $0.originId == originId }) else { return }
        
        // Create a mapping of the reordered priorities
        var scanlatorPriorityMap: [Int64: Int] = [:]
        for (index, scanlator) in reorderedScanlators.enumerated() {
            if let scanlatorId = scanlator.scanlator.id {
                scanlatorPriorityMap[scanlatorId] = index
            }
        }
        
        // Build complete priority list including unchanged scanlators
        let newPriorities = allScanlators.compactMap { scanlator -> (scanlatorId: Int64, priority: Int)? in
            guard let scanlatorId = scanlator.scanlator.id else { return nil }
            
            if let newPriority = scanlatorPriorityMap[scanlatorId] {
                return (scanlatorId: scanlatorId, priority: newPriority)
            } else {
                // Keep original priority for unchanged scanlators
                return (scanlatorId: scanlatorId, priority: scanlator.priority)
            }
        }
        
        do {
            try updateScanlatorPriorityUseCase.execute(originId: originId, newPriorities: newPriorities)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    func updateMangaSettings(showAllChapters: Bool? = nil, showHalfChapters: Bool? = nil) {
        guard let mangaId = details?.manga.id else { return }
        
        do {
            try updateMangaSettingsUseCase.execute(
                mangaId: mangaId,
                showAllChapters: showAllChapters,
                showHalfChapters: showHalfChapters
            )
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
}

// MARK: - Queue Observation

extension DetailsViewModel {
    private func observeMetadataRefreshState() {
        // Check for active operations on initialization
        if let existingOperation = QueueProvider.shared.operations[entry.queueOperationId],
           case .metadataRefresh = existingOperation.type,
           existingOperation.state.isActive {
            // Active refresh found - wait for completion
            self.waitingForMetadataRefresh = true
        }
        
        // Set up observer for queue state changes
        QueueProvider.shared.$operations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] operations in
                guard let self = self,
                      let operation = operations[entry.queueOperationId],
                      case .metadataRefresh = operation.type else { return }
                
                self.handleQueueStateChange(operation.state)
            }
            .store(in: &cancellables)
    }
    
    private func handleQueueStateChange(_ operationState: QueueOperationState) {
        switch operationState {
        case .pending:
            // Transition to refreshing if we have loaded data
            if case .success(let currentDetails) = self.state {
                withAnimation {
                    self.state = .refreshing(currentDetails, progress: 0.0)
                }
            }
            
        case .ongoing(let progress):
            // Update progress if already refreshing
            if case .refreshing(let currentDetails, _) = self.state {
                withAnimation {
                    self.state = .refreshing(currentDetails, progress: progress)
                }
            }
            
        case .completed:
            // Handle completion based on current state
            if self.waitingForMetadataRefresh {
                self.waitingForMetadataRefresh = false
                self.loadDetails()
            } else if case .refreshing = self.state {
                self.loadDetails()
            }
            
        case .failed(let error):
            // Handle failure based on current state
            if self.waitingForMetadataRefresh {
                self.waitingForMetadataRefresh = false
                self.loadDetails() // Try loading with cached data
            } else if case .refreshing = self.state {
                withAnimation {
                    self.state = .error(error)
                }
            }
            
        case .cancelled:
            // Handle cancellation based on current state
            if self.waitingForMetadataRefresh {
                self.waitingForMetadataRefresh = false
                self.loadDetails()
            } else if case .refreshing(let currentDetails, _) = self.state {
                withAnimation {
                    self.state = .success(currentDetails)
                }
            }
        }
    }
}

// MARK: - Types

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

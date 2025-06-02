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
    
    typealias ChapterId = Int64
    
    // MARK: - Properties
    private(set) var entry: Entry
    private(set) var resolvedOrientation: Orientation?
    private var context: Source?
    private var options: [Detail] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Use Cases
    private let getMangaDetailUseCase: GetMangaDetailUseCase
    private let resolveMangaOrientationUseCase: ResolveMangaOrientationUseCase
    private let toggleMangaInLibraryUseCase: ToggleMangaInLibraryUseCase
    private let addMangaOriginUseCase: AddMangaOriginUseCase
    private let markAllChaptersUseCase: MarkAllChaptersUseCase
    private let updateChapterProgressUseCase: UpdateChapterProgressUseCase
    private let updateMangaCoverUseCase: UpdateMangaCoverUseCase
    // MARK: - Downloading
    private let downloadChapterUseCase: DownloadChapterUseCase
    
    
    // MARK: - Initialization
    init(entry: Entry, context: Source?) {
        self.entry = entry
        self.context = context
        
        let injector = DependencyInjector.shared
        self.getMangaDetailUseCase = injector.makeGetMangaDetailUseCase()
        self.resolveMangaOrientationUseCase = injector.makeResolveMangaOrientationUseCase()
        self.toggleMangaInLibraryUseCase = injector.makeToggleMangaInLibraryUseCase()
        self.addMangaOriginUseCase = injector.makeAddMangaOriginUseCase()
        self.markAllChaptersUseCase = injector.makeMarkAllChaptersUseCase()
        self.updateChapterProgressUseCase = injector.makeUpdateChapterProgressUseCase()
        self.downloadChapterUseCase = injector.makeDownloadChapterUseCase()
        self.updateMangaCoverUseCase = injector.makeUpdateMangaCoverUseCase()
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
        case .conflict: return "conflict"
        }
    }
}

// MARK: - Data Loading
extension DetailsViewModel {
    func loadDetails() {
        state = .loading
        
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
                        self.resolvedOrientation = self.resolveMangaOrientationUseCase.execute(detail: first)
                    } else {
                        self.options = []
                        self.state = .empty
                    }
                }
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
    func toggleInLibrary() {
        guard case let .success(details) = state,
              let mangaId = details.manga.id else { return }
        
        do {
            try toggleMangaInLibraryUseCase.execute(
                mangaId: mangaId,
                newValue: !details.manga.inLibrary
            )
        } catch {
            state = .error(error)
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
            state = .error(error)
        }
    }
    
    func markChapter(asRead: Bool, for chapter: ChapterExtended) {
        do {
            try updateChapterProgressUseCase.execute(
                chapter: chapter.chapter,
                newProgress: asRead ? 1.0 : 0.0,
                override: true
            )
        }
        catch {
            state = .error(error)
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
            state = .error(error)
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
            state = .error(error)
        }
    }
    
    func updateMangaCover(_ cover: Cover) {
        guard let mangaId = details?.manga.id,
              let coverId = cover.id else { return }
        
        do {
            try updateMangaCoverUseCase.execute(mangaId: mangaId, coverId: coverId)
        } catch {
            state = .error(error)
        }
    }
}

// MARK: - Downloads
extension DetailsViewModel {
    func downloadChapter(_ chapter: Chapter) {
        QueueProvider.shared.downloadChapter(chapter)
    }
}

// MARK: - View State
extension DetailsViewModel {
    enum ViewState {
        case loading
        case conflict([Detail])
        case success(Detail)
        case error(Error)
        case empty
    }
    
    struct ConfirmationRequest {
        let title: String
        let message: String
        let detail: Detail
    }
}

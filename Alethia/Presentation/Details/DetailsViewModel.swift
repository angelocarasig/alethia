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
    @Published var confirmationRequest: ConfirmationRequest? = nil
    
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
    private let markAllChaptersUseCase: MarkAllChaptersUseCase
    private let updateChapterProgressUseCase: UpdateChapterProgressUseCase
    
    // MARK: - Initialization
    init(entry: Entry, context: Source?) {
        self.entry = entry
        self.context = context
        
        self.getMangaDetailUseCase = DependencyInjector.shared.makeGetMangaDetailUseCase()
        self.resolveMangaOrientationUseCase = DependencyInjector.shared.makeResolveMangaOrientationUseCase()
        self.toggleMangaInLibraryUseCase = DependencyInjector.shared.makeToggleMangaInLibraryUseCase()
        self.markAllChaptersUseCase = DependencyInjector.shared.makeMarkAllChaptersUseCase()
        self.updateChapterProgressUseCase = DependencyInjector.shared.makeUpdateChapterProgressUseCase()
    }
}

// MARK: - Computed Properties
extension DetailsViewModel {
    var sourcePresent: Bool {
        guard case let .success(details) = state,
              details.manga.inLibrary else { return false }
        
        return details.origins.contains {
            entry.fetchUrl?.decodeUri.contains($0.slug.decodeUri) ?? false
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

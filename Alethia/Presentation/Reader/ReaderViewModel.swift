//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 22/5/2025.
//

import SwiftUI
import Combine
import Kingfisher
import Drops

struct Page: Identifiable, Hashable, Sendable {
    var id: Int { pageNumber }
    
    let underlyingChapter: ChapterExtended
    let pageNumber: Int
    let pageUrl: String
    let pageReferer: String
    
    let isFirstPage: Bool
    let isLastPage: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

final class ReaderViewModel: ObservableObject {
    // UI
    @Published var state: ReaderState = .idle
    @Published var endDetailsVisible: Bool = false
    @Published var isScrolling: Bool = false                // disable slider while scrolling
    @Published var didScrollScrubber: Bool = false          // indicate when scrolling via slider happened
    @Published private(set) var showControls: Bool = false
    @Published private(set) var totalPages: Int = 0
    @Published private(set) var currentPage: Page? = nil
    @Published private(set) var orientation: Orientation
    
    let mangaTitle: String
    
    // Tracking
    @Published private(set) var currentChapter: ChapterExtended
    private(set) var recommendations: RecommendedEntries? = nil
    private(set) var chapters: ChapterList
    private var mangaId: Int64
    
    // Internal
    @Published private var userWantsControlsVisible: Bool = false
    private var prefetcher: ImagePrefetcher? = nil
    private var isUpdatingFromSlider: Bool = false
    
    // Use-Cases
    private var cancellables = Set<AnyCancellable>()
    private let getChapterContentsUseCase: GetChapterContentsUseCase
    private let updateMangaOrientationUseCase: UpdateMangaOrientationUseCase
    private let updateChapterProgressUseCase: UpdateChapterProgressUseCase // on exit
    private let markChapterReadUseCase: MarkChapterReadUseCase // on next
    private let getRecommendationsUseCase: GetRecommendationsUseCase
    
    init(
        mangaId: Int64,
        mangaTitle: String,
        orientation: Orientation,
        currentChapter: ChapterExtended,
        chapters: [ChapterExtended]
    ) {
        self.mangaId = mangaId
        self.mangaTitle = mangaTitle
        self.orientation = orientation
        self.currentChapter = currentChapter
        self.chapters = ChapterList(chapters: chapters)
        
        let injector = DependencyInjector.shared
        self.getChapterContentsUseCase = injector.makeGetChapterContentsUseCase()
        self.updateMangaOrientationUseCase = injector.makeUpdateMangaOrientationUseCase()
        self.updateChapterProgressUseCase = injector.makeUpdateChapterProgressUseCase()
        self.markChapterReadUseCase = injector.makeMarkChapterReadUseCase()
        self.getRecommendationsUseCase = injector.makeGetRecommendationsUseCase()
        
        setupControls()
    }
}

// MARK: State
extension ReaderViewModel {
    enum ReaderState {
        case idle
        case loading
        case loaded([Page])
        case error(Error)
    }
}

// MARK: Computed
extension ReaderViewModel {
    var nextChapter: ChapterExtended? {
        if let chapter = currentPage?.underlyingChapter {
            return chapters.findNode(for: chapter)?.next?.chapter
        }
        
        return nil
    }
    
    var canGoForward: Bool {
        return chapters.findNode(for: currentChapter)?.next != nil
    }
    
    var canGoBackward: Bool {
        return chapters.findNode(for: currentChapter)?.previous != nil
    }
    
    private var canShowControls: Bool {
        // Must be in loaded state
        guard case .loaded(let pages) = state else {
            return false
        }
        
        // Must not be showing end details
        guard !endDetailsVisible else {
            return false
        }
        
        // Must have valid pages
        guard !pages.isEmpty else {
            return false
        }
        
        return true
    }
}

// MARK: Chapter Management
extension ReaderViewModel {
    @MainActor
    func loadNextChapter() async -> Void {
        guard let currentNode = chapters.findNode(for: currentChapter),
              let nextChapter = currentNode.next else {
            return
        }
        withAnimation {
            self.state = .loading
            self.currentChapter = nextChapter.chapter
        }
        await loadChapter()
    }
    
    @MainActor
    func loadPrevChapter() async -> Void {
        guard let currentNode = chapters.findNode(for: currentChapter),
              let prevChapter = currentNode.previous else {
            return
        }
        withAnimation {
            self.state = .loading
            self.currentChapter = prevChapter.chapter
        }
        await loadChapter()
    }
    
    @MainActor
    func loadChapter(with chapter: ChapterExtended) async -> Void {
        currentChapter = chapter
        await loadChapter()
    }
    
    @MainActor
    func loadChapter() async -> Void {
        withAnimation {
            self.state = .loading
        }
        
        do {
            let pages = try await getChapterContentsUseCase.execute(chapter: currentChapter.chapter)
            
            let recommendations = try getRecommendationsUseCase.execute(mangaId: mangaId)
            
            let mappedPages = pages
                .enumerated()
                .map { index, element in
                    Page(
                        underlyingChapter: currentChapter,
                        pageNumber: index + 1,
                        pageUrl: element,
                        pageReferer: currentChapter.origin.referer,
                        isFirstPage: index == 0,
                        isLastPage: index == pages.count - 1
                    )
                }
            
            verifyOrientation()
            
            withAnimation {
                self.recommendations = recommendations
                self.totalPages = mappedPages.count
                self.state = .loaded(mappedPages)
            }
        }
        catch {
            withAnimation {
                self.state = .error(error)
            }
        }
    }
    
    func updateCurrentPage(page: Page) -> Void {
        currentPage = page
        
        // Use weak self to prevent retain cycles
        DispatchQueue.main.async { [weak self] in
            self?.prefetch()
        }
    }
    
    func updateCurrentPage(pageNumber: Int?) -> Void {
        guard let pageNumber = pageNumber else { return }
        
        // Check if we're already on this page
        if let current = currentPage, current.pageNumber == pageNumber {
            return
        }
        
        // Find the page with this number
        guard case .loaded(let pages) = state,
              let page = pages.first(where: { $0.pageNumber == pageNumber }) else {
            return
        }
        
        currentPage = page
        
        // Prefetch on main queue
        DispatchQueue.main.async { [weak self] in
            self?.prefetch()
        }
    }
    
    func updateChapterProgress(didCompleteChapter: Bool, completion: (() -> Void)? = nil) -> Void {
        do {
            if didCompleteChapter {
                try markChapterReadUseCase.execute(chapter: currentChapter.chapter)
                completion?()
                return
            }
            
            // get current chapter progress
            guard let currentPage = currentPage else {
                completion?()
                return
            }
            
            let progress: Double = totalPages > 0
            ? Double(currentPage.pageNumber) / Double(totalPages)
            : 0.0
            
            try updateChapterProgressUseCase.execute(chapter: currentChapter.chapter, newProgress: progress)
            completion?()
        }
        catch {
            state = .error(error)
            // completion is NOT called here, so dismiss() won't happen if there's an error
        }
    }
}

// MARK: Controls
extension ReaderViewModel {
    func toggleOrientation() {
        orientation.cycle()
        handleOrientationChange()
    }
    
    func toggleControls() {
        userWantsControlsVisible.toggle()
        updateControlsVisibility()
    }
    
    private func updateControlsVisibility() {
        let shouldShow = userWantsControlsVisible && canShowControls
        
        guard shouldShow != showControls else { return }
        
        withAnimation {
            showControls = shouldShow
        }
    }
    
    private func setupControls() {
        Publishers.CombineLatest3(
            $endDetailsVisible,
            $state,
            $userWantsControlsVisible
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateControlsVisibility()
        }
        .store(in: &cancellables)
    }
}

// MARK: Internal
private extension ReaderViewModel {
    private func prefetch() -> Void {
        guard case .loaded(let pages) = state,
              let currentPage = currentPage else { return }
        
        prefetcher?.stop()
        
        guard let currentIndex = pages.firstIndex(where: { $0.id == currentPage.id }) else { return }
        
        let prefetchRange = 5
        let startIndex = max(0, currentIndex - prefetchRange)
        let endIndex = min(pages.count - 1, currentIndex + prefetchRange)
        
        let images: [URL] = Array(pages[startIndex...endIndex])
            .compactMap { URL(string: $0.pageUrl) }
        
        guard !images.isEmpty else { return }
        
        prefetcher = ImagePrefetcher(
            urls: images,
            options: KingfisherProvider.prefetchOptions
        )
        
        prefetcher?.start()
    }
    
    /// Handles orientation changes by validating infinite scroll requirements and persisting changes
    private func handleOrientationChange() {
        validateInfiniteScrollRequirements()
        persistOrientationChange()
    }
    
    /// Checks if infinite scroll orientation is valid based on page count
    private func validateInfiniteScrollRequirements() {
        guard orientation == .Infinite,
              case .loaded(let pages) = state,
              // TODO:
              pages.count <= 3 else {
            return
        }
        
        showInfiniteScrollSkippedAlert(pageCount: pages.count)
        orientation.cycle()
    }
    
    /// Shows alert when infinite scroll is skipped due to insufficient pages
    private func showInfiniteScrollSkippedAlert(pageCount: Int) {
        Drops.show(Drop(
            title: "Infinite Scrolling Was Skipped",
            subtitle: "Current orientation has fewer than \(3) pages.",
            icon: UIImage(systemName: "xmark")?.withTintColor(.red, renderingMode: .alwaysOriginal),
            position: .top
        ))
    }
    
    /// Persists the current orientation to the database
    private func persistOrientationChange() {
        do {
            try updateMangaOrientationUseCase.execute(mangaId: mangaId, orientation: orientation)
        } catch {
            withAnimation {
                state = .error(error)
            }
        }
    }
    
    /// Verifies orientation after loading chapter content
    private func verifyOrientation() {
        handleOrientationChange()
    }
}

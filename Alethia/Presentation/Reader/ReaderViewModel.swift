//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation
import SwiftUI
import Combine

struct ReaderState: Hashable {
    var chapter: ChapterExtended
    var pageNumber: Int
    var pageCount: Int
    var hasPreviousChapter: Bool
    var hasNextChapter: Bool
    
    static var placeholder: Self {
        .init(
            chapter: ChapterExtended.placeholder,
            pageNumber: 0,
            pageCount: 0,
            hasPreviousChapter: false,
            hasNextChapter: false
        )
    }
}

struct ReaderPendingState: Hashable {
    var chapter: ChapterExtended
    var pageIndex: Int?
    var pageOffset: CGFloat?
}

struct SliderControl: Hashable {
    var current: Double = 0.0
    var isScrubbing = false
}

final class ReaderViewModel: ObservableObject {
    // Page-tracking
    @Published private(set) var currentPage: Page?
    @Published var lastTrackedPage: Page? // to determine transition direction
    
    // Tracking
    @Published private(set) var loadedState: [Slug: Loadable<Bool>]
    @Published private(set) var pendingState: ReaderPendingState?
    
    // UI
    let title: String
    @Published private(set) var orientation: Orientation
    @Published var readerState: ReaderState
    @Published private(set) var showControls: Bool
    @Published var sliderControls: SliderControl = .init()
    
    // Navigation
    private(set) var currentChapter: ChapterExtended
    private(set) var chapters: ChapterExtendedList
    
    // Use-cases
    private var cancellables: Set<AnyCancellable>
    private let getChapterContentsUseCase: GetChapterContentsUseCase
    
    init(
        title: String,
        orientation: Orientation,
        startChapter: ChapterExtended,
        chapters: [ChapterExtended]
    ) {
        // Page-tracking
        self.currentPage = nil
        self.lastTrackedPage = nil
        
        // Tracking
        self.loadedState = [:]
        // TODO: Handle loading from certain point
        self.pendingState = .init(chapter: startChapter, pageIndex: nil, pageOffset: nil)
        
        // UI
        self.title = title
        self.orientation = orientation
        self.readerState = .placeholder
        self.showControls = true
        
        // Navigation
        self.currentChapter = startChapter
        self.chapters = ChapterExtendedList(chapters: chapters)
        
        // Use-Cases
        self.cancellables = []
        self.getChapterContentsUseCase = DependencyInjector.shared.makeGetChapterContentsUseCase()
    }
    
    @MainActor
    func updateChapterState(for chapter: ChapterExtended, state: Loadable<Bool>) {
        loadedState.updateValue(state, forKey: chapter.chapter.slug)
    }
    
    func getChapterContents(chapter: ChapterExtended) async throws -> [Page] {
        let urls = try await getChapterContentsUseCase.execute(chapter: chapter.chapter)
        
        return urls.enumerated().map { index, url in
            Page(
                chapter: chapter.chapter,
                pageNumber: index + 1,
                totalPages: urls.count,
                contentUrl: url,
                contentReferer: chapter.origin.referer,
                isFirstPage: index == 0,
                isLastPage: index == urls.count - 1
            )
        }
    }
}

// MARK: Chapter loading
extension ReaderViewModel {
    @MainActor
    func updateViewerStateChapter(_ chapter: ChapterExtended) {
        readerState.chapter = chapter
        didChangeViewerStateChapter(with: chapter)
    }
    
    @MainActor
    func updateViewerStateChapter(_ newChapter: Chapter) {
        if let chapter: ChapterExtended = chapters.getChapterById(forChapterSlug: newChapter.slug)?.chapter {
            updateViewerStateChapter(chapter)
        }
    }
    
    @MainActor
    func updateViewerState(with page: Page) {
        readerState.pageNumber = page.pageNumber
    }
    
    @MainActor
    func updateViewerState(with transition: Transition) {
        guard let count = transition.pageCount else { return }
        readerState.pageNumber = count // Set to last page
    }
    
    func didChangeViewerStateChapter(with chapter: ChapterExtended) {
        let hasNext = chapters.nextChapter(for: chapter.chapter.slug) != nil
        let hasPrev = chapters.nextChapter(for: chapter.chapter.slug) != nil
            
        readerState.hasNextChapter = hasNext
        readerState.hasPreviousChapter = hasPrev
        
        // TODO: See if it breaks here
//        readerState.pageCount = pages
    }
}

// MARK: Events
extension ReaderViewModel {
    func isCurrentlyReading(_ chapter: Chapter) -> Bool {
        chapter == readerState.chapter.chapter
    }
}

// MARK: Property modifiers
extension ReaderViewModel {
    func clearPendingState() {
        self.pendingState = nil
    }
}

//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import SwiftUI
import Combine
import OrderedCollections

enum ReaderState: Equatable {
    case placeholder
    case loading
    case idle
    case error(Error)
    
    static func == (lhs: ReaderState, rhs: ReaderState) -> Bool {
        switch (lhs, rhs) {
        case (.placeholder, .placeholder),
            (.loading, .loading),
            (.idle, .idle):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
final class ReaderViewModel: ObservableObject {
    // MARK: Tracking
    @Published var currentPanel: ReaderPanel? = nil
    private(set) var startingChapter: Chapter
    private(set) var chapters: ReaderChapterList
    private(set) var loadedChapters: [Slug: ReaderPanelState] = [:] /// Dictionary of each chapter's loaded state and content
    
    // MARK: Controls
    private(set) var orientation: Orientation
    
    // MARK: UI
    @Published private(set) var state: ReaderState
    private(set) var sections: OrderedSet<Slug> = [] /// maintains ordered state in how to display loaded chapters
    
    // MARK: Metadata
    let mangaTitle: String
    
    // MARK: Use-cases
    var cancellables = Set<AnyCancellable>()
    private let getChapterContentsUseCase: GetChapterContentsUseCase
    private let updateChapterProgressUseCase: UpdateChapterProgressUseCase
    private let markChapterReadUseCase: MarkChapterReadUseCase
    
    init(
        title: String,
        orientation: Orientation,
        startingChapter: Chapter,
        chapters: [ChapterExtended]
    ) {
        self.state = .placeholder
        self.mangaTitle = title
        self.orientation = orientation
        self.startingChapter = startingChapter
        self.chapters = ReaderChapterList(chapters: chapters)
        
        print(self.chapters.debugDescription)
        
        self.getChapterContentsUseCase = DependencyInjector.shared.makeGetChapterContentsUseCase()
        self.updateChapterProgressUseCase = DependencyInjector.shared.makeUpdateChapterProgressUseCase()
        self.markChapterReadUseCase = DependencyInjector.shared.makeMarkChapterReadUseCase()
        
        Task {
            await loadInitialChapter(startingChapter)
        }
    }
    
    func reset() {
        self.cancellables.removeAll()
        self.sections.removeAll()
        self.loadedChapters.removeAll()
    }
    
    func loadInitialChapter(_ chapter: Chapter) async {
        await loadChapter(chapter: chapter, loadType: .update)
    }
    
    func loadPreviousChapter() async {
        guard let currentPanel = currentPanel else { return }
        
        let chapterExtended: ChapterExtended
        
        switch currentPanel {
        case .page(let page):
            chapterExtended = page.underlyingChapter
        case .transition(let transition):
            chapterExtended = transition.from
        }
        
        guard let node = chapters.findNode(where: { $0.chapter.slug == chapterExtended.chapter.slug }),
              let prev = node.prev
        else { return }
        
        await loadChapter(chapter: prev.chapter.chapter, loadType: .previous)
    }
    
    func loadNextChapter() async {
        print("Loading Next Chapter...")
        guard let currentPanel = currentPanel else { return }
        
        let chapterExtended: ChapterExtended
        
        switch currentPanel {
        case .page(let page):
            chapterExtended = page.underlyingChapter
        case .transition(let transition):
            chapterExtended = transition.from
        }
        
        guard let node = chapters.findNode(where: { $0.chapter.slug == chapterExtended.chapter.slug }),
              let next = node.next
        else { return }
        
        await loadChapter(chapter: next.chapter.chapter, loadType: .next)
    }
}

// MARK: Sections
extension ReaderViewModel {
    func updateSection(for slug: Slug, at direction: ChapterLoadType) {
        switch direction {
        case .next:
            sections.append(slug)
        case .previous:
            sections.insert(slug, at: 0)
        case .update:
            // In this case we are jumping to a different section so clear all first
            sections.removeAll()
            sections.append(slug)
        }
    }
}

// MARK: Functions
extension ReaderViewModel {
    func hasLoadedChapter(_ node: ReaderChapterListNode) -> Bool {
        // First, log the type and value for debugging
        print("Slug type: \(type(of: node.chapter.chapter.slug)), value: \(node.chapter.chapter.slug)")
        
        // Ensure we're using a string-based lookup
        let slugString = String(describing: node.chapter.chapter.slug)
        
        // Check if slug exists in dictionary
        return loadedChapters[slugString] != nil
    }
    
    func hasLoadedChapter(_ chapter: ChapterExtended) -> Bool {
        guard let panelState = loadedChapters[chapter.chapter.slug],
              panelState.state == .loaded
        else { return false }
        
        return true
    }
    
    func loadChapter(chapter: Chapter, loadType: ChapterLoadType) async -> Void {
        guard let chapterNode: ReaderChapterListNode = chapters.findNode(where: { $0.chapter.slug == chapter.slug }) else {
            state = .error(ChapterError.notFound)
            return
        }
        
        // If found, set state to loading
        await MainActor.run {
            state = .loading
        }
        
        // check if already preloaded
        if !hasLoadedChapter(chapterNode) {
            await preloadChapter(chapterNode)
        }
        
        updateSection(for: chapterNode.chapter.chapter.slug, at: loadType)
        
        // Once completed set status back to idle
        await MainActor.run {
            state = .idle
        }
    }
    
    func preloadChapter(after chapter: ChapterExtended) async -> Void {
        guard let node: ReaderChapterListNode = chapters.findNode(where: { $0.chapter.slug == chapter.chapter.slug }),
              let next: ReaderChapterListNode = node.next
        else { return }
        
        await preloadChapter(next)
    }
    
    func preloadChapter(before chapter: ChapterExtended) async -> Void {
        guard let node: ReaderChapterListNode = chapters.findNode(where: { $0.chapter.slug == chapter.chapter.slug }),
              let prev: ReaderChapterListNode = node.prev
        else { return }
        
        await preloadChapter(prev)
    }
    
    /// Inserts into the loadedChapters array
    private func preloadChapter(_ node: ReaderChapterListNode) async -> Void {
        guard !hasLoadedChapter(node) else { return }
        
        let chapterSlug: Slug = node.chapter.chapter.slug
        do {
            updateLoadedChapters(for: chapterSlug)
            
            let contents: [String] = try await getChapterContents(for: node.chapter.chapter)
            guard !contents.isEmpty else { throw ChapterError.noContent }
            
            var panels: [ReaderPanel] = []
            
            // insert start transition
            panels.append(
                .transition(
                    .init(
                        from: node.chapter,
                        to: node.next?.chapter,
                        pageCount: contents.count
                    )
                )
            )
            
            // insert pages
            panels.append(
                contentsOf: contents.enumerated().map { index, url in
                        .page(
                            .init(
                                underlyingChapter: node.chapter,
                                pageNumber: index + 1,
                                pageCount: contents.count,
                                isFirstPage: index == 0,
                                isLastPage: index == contents.count - 1,
                                url: url
                            )
                        )
                })
            
            // insert end transition
            panels.append(
                .transition(
                    .init(
                        from: node.chapter,
                        to: node.next?.chapter,
                        pageCount: contents.count
                    )
                )
            )
            
            updateLoadedChapters(for: chapterSlug, with: panels)
        }
        catch {
            state = .error(error)
        }
    }
}

// MARK: Util
extension ReaderViewModel {
    private func updateLoadedChapters(for slug: Slug, with contents: [ReaderPanel]? = nil, error: Error? = nil) -> Void {
        var state: PanelLoadedState
        
        if contents != nil {
            state = .loaded
        }
        else if let error = error {
            state = .error(error)
        }
        else {
            state = .loading
        }
        
        loadedChapters[slug] = .init(panels: contents, state: state)
    }
}

// MARK: Use-Cases
extension ReaderViewModel {
    private func getChapterContents(for chapter: Chapter) async throws -> [String] {
        return try await getChapterContentsUseCase.execute(chapter: chapter)
    }
}

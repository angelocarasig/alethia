//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import SwiftUI
import Kingfisher

@MainActor
final class ReaderViewModel: ObservableObject {
    // Pages
    @Published private(set) var pages: [Page] = []
    @Published var currentPage: Page? = nil { didSet { prefetch() }}
    
    // Overlay
    @Published private(set) var showNotificationBanner: String? = nil
    @Published var showOverlay: Bool = false
    @Published var onHorizontalPageTransition: Bool = false
    @Published var scrolledFromSlider: Bool = false
    
    // Handling
    @Published private(set) var chapterLoaded: Lock = .unlocked
    @Published private(set) var errorMessage: String? = nil
    
    var activeChapter: ChapterExtended? {
        currentPage?.getUnderlyingChapter(chapters: chapters)
    }
    
    private(set) var mangaTitle: String
    private(set) var orientation: Orientation
    private(set) var chapters: [ChapterExtended]
    
    private var initialChapterIndex: Int
    private var prefetcher: ImagePrefetcher? = nil
    private var getChapterContentsUseCase: GetChapterContentsUseCase
    private var updateChapterProgressUseCase: UpdateChapterProgressUseCase
    private var markChapterReadUseCase: MarkChapterReadUseCase
    
    init(
        title: String,
        orientation: Orientation,
        chapters: [ChapterExtended],
        currentChapterIndex: Int
    ) {
        self.mangaTitle = title
        self.orientation = orientation
        self.chapters = chapters
        self.initialChapterIndex = currentChapterIndex
        
        self.getChapterContentsUseCase = DependencyInjector.shared.makeGetChapterContentsUseCase()
        self.updateChapterProgressUseCase = DependencyInjector.shared.makeUpdateChapterProgressUseCase()
        self.markChapterReadUseCase = DependencyInjector.shared.makeMarkChapterReadUseCase()
        
        Task {
            print("Loading Chapter from INIT")
            await loadChapter(at: currentChapterIndex)
        }
    }
}

// MARK: Data fetching
extension ReaderViewModel {
    func loadChapter(at index: Int) async {
        if pages.contains(where: { $0.chapterIndex == index }) {
            return
        }
        
        guard index >= 0 && index < chapters.count else { return }
        
        do {
            let urls = try await getChapterContentsUseCase.execute(chapter: chapters[index].chapter)
            let newPages = makePages(from: urls, index: index)
            
            await MainActor.run {
                // MARK: Initial Load
                if pages.isEmpty {
                    pages = newPages
                }
                // MARK: Previous Chapter
                else if let first = pages.first, index > first.chapterIndex {
                    pages.insert(contentsOf: newPages, at: 0)
                }
                // MARK: Next Chapter
                else if let last = pages.last, index < last.chapterIndex {
                    try? onNextChapterLoaded()
                    
                    pages.append(contentsOf: newPages)
                }
                else {
                    pages = newPages
                }
                
                chapterLoaded = .locked
            }
        } catch {
            withAnimation { @MainActor in
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func canLoadPrevious(chapter: ChapterExtended) -> Bool {
        guard let index = chapters.firstIndex(where: { $0.chapter.id == chapter.chapter.id }) else {
            return false
        }
        return index > 0
    }
    
    func canLoadNext(chapter: ChapterExtended) -> Bool {
        guard let index = chapters.firstIndex(where: { $0.chapter.id == chapter.chapter.id }) else {
            return false
        }
        return index < chapters.count - 1
    }
    
    private func makePages(from urls: [String], index: Int) -> [Page] {
        let total = urls.count
        return urls.enumerated().map { idx, url in
            Page(
                url: url,
                chapterIndex: index,
                chapterNumber: chapters[index].chapter.number,
                pageNumber: idx + 1,
                isFirstPage: idx == 0,
                isLastPage:  idx == total - 1
            )
        }
    }
}

// MARK: Controls for slider buttons
extension ReaderViewModel {
    private var pagesInActiveChapter: [Page] {
        guard let idx = currentPage?.chapterIndex else { return [] }
        return pages.filter { $0.chapterIndex == idx }
    }
    
    func goToFirstPageInChapter() {
        guard let first = pagesInActiveChapter.first else { return }
        scrolledFromSlider = true
        currentPage = first
    }
    
    func goToLastPageInChapter() {
        guard let last = pagesInActiveChapter.last else { return }
        scrolledFromSlider = true
        currentPage = last
    }
}

// MARK: Chapter Progression
extension ReaderViewModel {
    func onReaderClose() {
        guard
            let activeChapter = activeChapter,
            let currentPage = currentPage,
            
                // If chapter progress is already completed don't update
            // let user manually mark it as unread before updating progress again
                activeChapter.chapter.progress < 1.0
        else { return }
        
        let pagesInChapter = pagesInActiveChapter
        let total = pagesInChapter.count
        
        guard total > 0 else { return }
        
        // MARK: Calculating progress of current chapter...
        let progress = Double(currentPage.pageNumber) / Double(total)
        
        do {
            try updateChapterProgressUseCase.execute(
                chapter: activeChapter.chapter,
                newProgress: progress
            )
        } catch {
            print("Failed to update progress:", error)
        }
        
        // if we're at the end, mark it read
        if progress >= 1.0 {
            do {
                try markChapterReadUseCase.execute(chapter: activeChapter.chapter)
            } catch {
                print("Failed to mark chapter read:", error)
            }
        }
    }
    
    private func onNextChapterLoaded() throws -> Void {
        if let activeChapter = activeChapter {
            // TODO: Handle if error thrown
            try markChapterReadUseCase.execute(chapter: activeChapter.chapter)
        }
    }
}

// MARK: Utils
extension ReaderViewModel {
    @MainActor
    func toggleReaderDirection() -> Void {
        chapterLoaded = .unlocked
        
        orientation.cycle()
        
        let modifiedOrientation: String = {
            switch orientation {
            case .Infinite:    return "Infinite Scrolling"
            case .Vertical:    return "Vertically Paginated"
            case .LeftToRight: return "Left → Right"
            case .RightToLeft: return "Right → Left"
            }
        }()
        
        showNotificationBanner(message: modifiedOrientation)
        
        pages.removeAll()
        let targetIndex = currentPage?.chapterIndex ?? initialChapterIndex
        
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            await self.loadChapter(at: targetIndex)
        }
    }
    
    private func showNotificationBanner(message: String) {
        withAnimation {
            showNotificationBanner = message
        }
        
        // schedule the hide after 1.5 second
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation {
                    showNotificationBanner = nil
                }
            }
        }
    }
    
    private func prefetch() -> Void {
        guard   let currentPage = currentPage,
                !pages.isEmpty
        else { return }
        
        let prefetchRange: Int = 5
        let start = max(
            0,
            currentPage.pageNumber - prefetchRange
        )
        let end = min(
            pages.count - 1,
            currentPage.pageNumber + prefetchRange
        )
        
        guard start <= end else { return }
        
        let urls: [URL] = Array(pages[start...end]).compactMap { URL(string: $0.url) }
        
        prefetcher?.stop()
        prefetcher = ImagePrefetcher(
            urls: urls,
            options: [.cacheMemoryOnly, .backgroundDecode],
            progressBlock: nil
        )
        prefetcher?.start()
    }
}

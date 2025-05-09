//
//  ReaderViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation
import SwiftUI
import Kingfisher

struct Page: Identifiable, Equatable, Hashable {
    var id: String { "\(chapterNumber)-\(pageNumber)"}
    
    let url: String
    let chapterIndex: Int
    let chapterNumber: Double
    let pageNumber: Int
    
    let isFirstPage: Bool
    let isLastPage:  Bool
    
    func getUnderlyingChapter(chapters: [ChapterExtended]) -> ChapterExtended {
        return chapters[chapterIndex]
    }
}

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published var showOverlay: Bool = false
    @Published var scrolledFromSlider: Bool = false
    @Published private(set) var chapterLoaded: Bool = false
    @Published private(set) var pages: [Page] = []
    @Published var currentPage: Page? = nil {
        didSet {
            prefetch()
        }
    }
    
    @Published private(set) var errorMessage: String? = nil
    
    var activeChapter: ChapterExtended? {
        currentPage?.getUnderlyingChapter(chapters: chapters)
    }
    
    private(set) var mangaTitle: String
    private(set) var chapters: [ChapterExtended]
    
    private var prefetcher: ImagePrefetcher? = nil
    private var getChapterContentsUseCase: GetChapterContentsUseCase
    
    init(title: String, chapters: [ChapterExtended], currentChapterIndex: Int) {
        self.mangaTitle = title
        self.chapters = chapters
        
        self.getChapterContentsUseCase = DependencyInjector.shared.makeGetChapterContentsUseCase()
        
        Task {
            print("Loading Chapter from INIT")
            await loadChapter(at: currentChapterIndex)
        }
    }
    
    func loadChapter(at index: Int) async {
        if pages.contains(where: { $0.chapterIndex == index }) {
            return
        }
        
        guard index >= 0 && index < chapters.count else { return }
        
        do {
            let urls = try await getChapterContentsUseCase.execute(chapter: chapters[index].chapter)
            let newPages = makePages(from: urls, index: index)
            
            await MainActor.run {
                if pages.isEmpty {
                    pages = newPages
                } else if let first = pages.first, index > first.chapterIndex {
                    pages.insert(contentsOf: newPages, at: 0)
                } else if let last = pages.last, index < last.chapterIndex {
                    pages.append(contentsOf: newPages)
                } else {
                    pages = newPages
                }
                
                chapterLoaded = true
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
    
    func prefetch() -> Void {
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
    
    /// Jump to the first page in the current chapter
    func goToFirstPageInChapter() {
        guard let first = pagesInActiveChapter.first else { return }
        scrolledFromSlider = true
        currentPage = first
    }
    
    /// Jump to the last page in the current chapter
    func goToLastPageInChapter() {
        guard let last = pagesInActiveChapter.last else { return }
        scrolledFromSlider = true
        currentPage = last
    }
}

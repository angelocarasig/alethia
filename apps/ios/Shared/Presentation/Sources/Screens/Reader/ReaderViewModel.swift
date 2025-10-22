//
//  ReaderViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI
import Domain
import Composition
import Reader

@MainActor
@Observable
final class ReaderViewModel {
    private(set) var chapters: [Chapter]
    private(set) var currentChapter: Chapter?
    private(set) var readingMode: ReadingMode
    
    private(set) var coordinator: ReaderCoordinator<AlethiaReaderDataSource>?
    private(set) var dataSource: AlethiaReaderDataSource
    
    var startingChapterId: Int64 {
        currentChapter?.id ?? chapters.first?.id ?? 0
    }
    
    var totalChapters: Int {
        chapters.count
    }
    
    var hasPreviousChapter: Bool {
        guard let current = currentChapter else { return false }
        return chapters.first?.id != current.id
    }
    
    var hasNextChapter: Bool {
        guard let current = currentChapter else { return false }
        return chapters.last?.id != current.id
    }
    
    init(chapters: [Chapter], startingChapterSlug: String) {
        self.chapters = chapters
        self.currentChapter = chapters.first(where: { $0.slug == startingChapterSlug })
        
        // map domain orientation to reading mode
        // TODO: Pass in manga orientation
        self.readingMode = Self.mapOrientation(.leftToRight)
        
        // initialize data source
        self.dataSource = AlethiaReaderDataSource(
            chapters: chapters,
            getChapterContentsUseCase: Injector.makeGetChapterContentsUseCase()
        )
    }
    
    func setupCoordinator() {
        coordinator = ReaderCoordinator<AlethiaReaderDataSource>()
    }
    
    func updateReadingMode(_ mode: ReadingMode) {
        readingMode = mode
    }
    
    func previousChapter() {
        guard let current = currentChapter,
              let currentIndex = chapters.firstIndex(where: { $0.id == current.id }),
              currentIndex > 0 else { return }
        
        let previous = chapters[currentIndex - 1]
        currentChapter = previous
        coordinator?.jumpToChapter(previous.id, animated: true)
    }
    
    func nextChapter() {
        guard let current = currentChapter,
              let currentIndex = chapters.firstIndex(where: { $0.id == current.id }),
              currentIndex < chapters.count - 1 else { return }
        
        let next = chapters[currentIndex + 1]
        currentChapter = next
        coordinator?.jumpToChapter(next.id, animated: true)
    }
    
    func jumpToPage(_ page: Int) {
        guard let chapter = currentChapter else { return }
        coordinator?.jumpToPage(page, in: chapter.id, animated: false)
    }
    
    private static func mapOrientation(_ orientation: Orientation) -> ReadingMode {
        switch orientation {
        case .leftToRight:
            return .leftToRight
        case .rightToLeft:
            return .rightToLeft
        case .vertical:
            return .vertical
        case .infinite:
            return .infinite
        case .unknown:
            return .leftToRight
        }
    }
}

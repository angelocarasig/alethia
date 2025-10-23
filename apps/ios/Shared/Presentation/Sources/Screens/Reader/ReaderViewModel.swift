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
    private(set) var readingMode: ReadingMode
    
    private(set) var coordinator: ReaderCoordinator<AlethiaReaderDataSource>?
    private(set) var dataSource: AlethiaReaderDataSource
    
    private let _startingChapterId: Int64
    
    // track last navigation direction for loading indicators
    private(set) var lastNavigationDirection: ReaderScreen.NavigationDirection?
    
    // computed properties that delegate to coordinator
    var currentChapter: Chapter? {
        coordinator?.currentChapter
    }
    
    var startingChapterId: Int64 {
        _startingChapterId
    }
    
    var totalChapters: Int {
        chapters.count
    }
    
    var hasPreviousChapter: Bool {
        coordinator?.canGoToPreviousChapter ?? false
    }
    
    var hasNextChapter: Bool {
        coordinator?.canGoToNextChapter ?? false
    }
    
    var isReady: Bool {
        coordinator?.isReady ?? false
    }
    
    var isLoadingInitial: Bool {
        coordinator?.isLoadingInitial ?? true
    }
    
    var isLoadingChapter: Bool {
        coordinator?.isLoadingChapter ?? false
    }
    
    var error: ReaderError? {
        coordinator?.error
    }
    
    init(chapters: [Chapter], startingChapter: Chapter, orientation: Orientation) {
        precondition(chapters.contains(where: { $0.id == startingChapter.id }),
                     "starting chapter must exist in chapters array")
        
        self.chapters = chapters
        self._startingChapterId = startingChapter.id
        self.readingMode = Self.mapOrientation(orientation)
        
        self.dataSource = AlethiaReaderDataSource(
            chapters: chapters,
            getChapterContentsUseCase: Injector.makeGetChapterContentsUseCase()
        )
        
        self.coordinator = ReaderCoordinator<AlethiaReaderDataSource>()
    }
    
    func setupCoordinator() {
        // coordinator already initialized in init
    }
    
    func updateReadingMode(_ mode: ReadingMode) {
        readingMode = mode
    }
    
    func previousChapter() {
        lastNavigationDirection = .previous
        coordinator?.previousChapter()
    }
    
    func nextChapter() {
        lastNavigationDirection = .next
        coordinator?.nextChapter()
    }
    
    func jumpToPage(_ page: Int) {
        guard let chapter = currentChapter else { return }
        coordinator?.jumpToPage(page, in: chapter.id, animated: false)
    }
    
    func retry() {
        lastNavigationDirection = nil
        coordinator?.retry()
    }
    
    func clearError() {
        coordinator?.clearError()
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

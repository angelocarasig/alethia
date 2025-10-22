//
//  ReaderCoordinator.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation
import UIKit

/// coordinator for managing reader state and interactions
@Observable
@MainActor
public final class ReaderCoordinator<DataSource: ReaderDataSource> {
    
    // MARK: - Public State
    
    public private(set) var currentPage: Int = 0
    public private(set) var currentChapter: DataSource.Chapter?
    public private(set) var totalPages: Int = 0
    public private(set) var isScrolling: Bool = false
    public private(set) var isLoadingChapter: Bool = false
    
    public var canGoToPreviousChapter: Bool {
        guard let reader = reader, let currentChapter = currentChapter else { return false }
        let navigation = reader.getNavigation(for: ChapterID(currentChapter.id))
        return navigation.previous != nil
    }
    
    public var canGoToNextChapter: Bool {
        guard let reader = reader, let currentChapter = currentChapter else { return false }
        let navigation = reader.getNavigation(for: ChapterID(currentChapter.id))
        return navigation.next != nil
    }
    
    public var totalChapters: Int {
        dataSource?.chapters.count ?? 0
    }
    
    // MARK: - Error Handling
    
    public var onError: (@MainActor @Sendable (Error) -> Void)?
    
    // MARK: - Internal
    
    private var reader: Reader?
    private var dataSource: DataSource?
    
    public init() {}
    
    // MARK: - Public API
    
    /// jump to specific page in a chapter
    public func jumpToPage(_ page: Int, in chapterId: DataSource.Chapter.ID, animated: Bool = false) {
        reader?.jumpToPage(page, in: ChapterID(chapterId), animated: animated)
    }
    
    /// jump to first page of a chapter
    public func jumpToChapter(_ chapterId: DataSource.Chapter.ID, animated: Bool = false) {
        reader?.jumpToChapter(ChapterID(chapterId), animated: animated)
    }
    
    /// navigate to next chapter
    public func nextChapter() {
        reader?.nextChapter()
    }
    
    /// navigate to previous chapter
    public func previousChapter() {
        reader?.previousChapter()
    }
    
    // MARK: - Internal Connection
    
    internal func attach(_ reader: Reader, dataSource: DataSource) {
        self.reader = reader
        self.dataSource = dataSource
        setupBindings()
        
        // initialize state immediately
        updateInitialState()
    }
    
    private func updateInitialState() {
        guard let reader = reader else { return }
        
        // set current page
        self.currentPage = reader.currentPage
        
        // set current chapter
        if let anyChapter = reader.currentChapter,
           let chapter: DataSource.Chapter = anyChapter.asChapter() {
            self.currentChapter = chapter
        }
        
        // set total pages - this is the key fix
        self.totalPages = reader.currentChapterPageCount
        
        // if total pages is still 0, wait a bit and try again
        if self.totalPages == 0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                self.totalPages = reader.currentChapterPageCount
            }
        }
    }
    
    private func setupBindings() {
        guard let reader = reader, dataSource != nil else { return }
        
        // bind page changes
        reader.onPageChange = { [weak self] page, anyChapter in
            guard let self = self else { return }
            Task { @MainActor in
                if let chapter: DataSource.Chapter = anyChapter.asChapter() {
                    self.currentPage = page
                    self.currentChapter = chapter
                    
                    // always update total pages when page changes
                    self.totalPages = reader.currentChapterPageCount
                }
            }
        }
        
        // bind chapter changes
        reader.onChapterChange = { [weak self] anyChapter in
            guard let self = self else { return }
            Task { @MainActor in
                if let chapter: DataSource.Chapter = anyChapter.asChapter() {
                    self.currentChapter = chapter
                    self.totalPages = reader.currentChapterPageCount
                }
            }
        }
        
        // bind scroll state
        reader.onScrollStateChange = { [weak self] scrolling in
            guard let self = self else { return }
            Task { @MainActor in
                self.isScrolling = scrolling
            }
        }
        
        // bind errors
        reader.onError = { [weak self] error in
            guard let self = self else { return }
            Task { @MainActor in
                self.onError?(error)
            }
        }
    }
}

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
    public private(set) var isLoadingInitial: Bool = true
    public private(set) var isLoadingChapter: Bool = false
    public private(set) var error: ReaderError?
    
    public var isReady: Bool {
        !isLoadingInitial && !isLoadingChapter && error == nil && totalPages > 0
    }
    
    public var canGoToPreviousChapter: Bool {
        guard let reader = reader, let currentChapter = currentChapter, isReady else { return false }
        let navigation = reader.getNavigation(for: ChapterID(currentChapter.id))
        return navigation.previous != nil
    }
    
    public var canGoToNextChapter: Bool {
        guard let reader = reader, let currentChapter = currentChapter, isReady else { return false }
        let navigation = reader.getNavigation(for: ChapterID(currentChapter.id))
        return navigation.next != nil
    }
    
    public var totalChapters: Int {
        dataSource?.chapters.count ?? 0
    }
    
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
        guard isReady else { return }
        isLoadingChapter = true
        reader?.nextChapter()
    }
    
    /// navigate to previous chapter
    public func previousChapter() {
        guard isReady else { return }
        isLoadingChapter = true
        reader?.previousChapter()
    }
    
    /// retry loading current chapter
    public func retry() {
        guard let currentChapter = currentChapter else { return }
        error = nil
        isLoadingInitial = true
        isLoadingChapter = false
        
        // trigger reload by jumping to same chapter
        jumpToChapter(currentChapter.id, animated: false)
    }
    
    /// clear error state
    public func clearError() {
        error = nil
    }
    
    // MARK: - Internal Connection
    
    internal func attach(_ reader: Reader, dataSource: DataSource) {
        self.reader = reader
        self.dataSource = dataSource
        setupBindings()
    }
    
    private func setupBindings() {
        guard let reader = reader, dataSource != nil else { return }
        
        reader.onPageChange = { [weak self] page, anyChapter in
            guard let self = self else { return }
            Task { @MainActor in
                if let chapter: DataSource.Chapter = anyChapter.asChapter() {
                    self.currentPage = page
                    self.currentChapter = chapter
                    self.totalPages = reader.currentChapterPageCount
                    
                    // if we have pages and were loading, mark as loaded
                    if self.totalPages > 0 {
                        self.isLoadingInitial = false
                        self.isLoadingChapter = false
                    }
                }
            }
        }
        
        reader.onChapterChange = { [weak self] anyChapter in
            guard let self = self else { return }
            Task { @MainActor in
                if let chapter: DataSource.Chapter = anyChapter.asChapter() {
                    self.currentChapter = chapter
                    self.totalPages = reader.currentChapterPageCount
                    
                    // if we have pages, mark as loaded
                    if self.totalPages > 0 {
                        self.isLoadingInitial = false
                        self.isLoadingChapter = false
                        
                        // clear any previous errors
                        if self.error != nil {
                            self.error = nil
                        }
                    }
                }
            }
        }
        
        reader.onScrollStateChange = { [weak self] scrolling in
            guard let self = self else { return }
            Task { @MainActor in
                self.isScrolling = scrolling
            }
        }
        
        reader.onError = { [weak self] error in
            guard let self = self else { return }
            Task { @MainActor in
                // determine if this is initial or subsequent chapter error
                if self.isLoadingInitial {
                    self.error = .initialChapterFailed(error)
                    self.isLoadingInitial = false
                } else if self.isLoadingChapter {
                    if let chapter = self.currentChapter {
                        self.error = .subsequentChapterFailed(chapterId: ChapterID(chapter.id), error)
                    } else {
                        self.error = .initialChapterFailed(error)
                    }
                    self.isLoadingChapter = false
                } else {
                    // error during normal operation
                    if let chapter = self.currentChapter {
                        self.error = .subsequentChapterFailed(chapterId: ChapterID(chapter.id), error)
                    } else {
                        self.error = .initialChapterFailed(error)
                    }
                }
            }
        }
        
        // add callback for when chapter loading completes successfully
        reader.onChapterLoadComplete = { [weak self] chapterId, pageCount in
            guard let self = self else { return }
            Task { @MainActor in
                // check if this is for the current chapter
                if let currentChapter = self.currentChapter,
                   ChapterID(currentChapter.id) == chapterId {
                    
                    if pageCount == 0 {
                        // chapter loaded but has no pages
                        self.error = .emptyPages(chapterId: chapterId)
                        self.isLoadingInitial = false
                        self.isLoadingChapter = false
                    } else {
                        // chapter loaded successfully
                        self.totalPages = pageCount
                        self.isLoadingInitial = false
                        self.isLoadingChapter = false
                        
                        // clear any previous errors
                        if self.error != nil {
                            self.error = nil
                        }
                    }
                }
            }
        }
    }
}

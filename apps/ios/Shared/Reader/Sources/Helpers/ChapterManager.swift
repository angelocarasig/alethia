//
//  ChapterManager.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// manages chapter loading state and logic
actor ChapterManager {
    private let chapters: [AnyReadableChapter]
    private let fetchPages: @Sendable (ChapterID) async throws -> [String]
    
    private var loadedChapters: [ChapterID: [String]] = [:]
    private var isLoadingPrevious = false
    private var isLoadingNext = false
    
    init(
        chapters: [AnyReadableChapter],
        fetchPages: @escaping @Sendable (ChapterID) async throws -> [String]
    ) {
        self.chapters = chapters
        self.fetchPages = fetchPages
    }
    
    func isChapterLoaded(_ chapterId: ChapterID) -> Bool {
        loadedChapters.keys.contains(chapterId)
    }
    
    func getLoadedChapters() -> [(id: ChapterID, pages: [String])] {
        return loadedChapters.map { (id: $0.key, pages: $0.value) }
    }
    
    func allImageURLs(orderedBy chapterIds: [ChapterID]) -> [String] {
        return chapterIds.flatMap { loadedChapters[$0] ?? [] }
    }
    
    func setChapter(_ imageURLs: [String], for chapterId: ChapterID) {
        loadedChapters[chapterId] = imageURLs
    }
    
    nonisolated func fetchChapter(for chapterId: ChapterID) async throws -> [String] {
        return try await fetchPages(chapterId)
    }
    
    func canLoadPrevious(current: ChapterID, previous: AnyReadableChapter?) -> Bool {
        guard !isLoadingPrevious, let previous = previous else { return false }
        return !isChapterLoaded(previous.id)
    }
    
    func canLoadNext(current: ChapterID, next: AnyReadableChapter?) -> Bool {
        guard !isLoadingNext, let next = next else { return false }
        return !isChapterLoaded(next.id)
    }
    
    func startLoadingPrevious() {
        isLoadingPrevious = true
    }
    
    func finishLoadingPrevious() {
        isLoadingPrevious = false
    }
    
    func startLoadingNext() {
        isLoadingNext = true
    }
    
    func finishLoadingNext() {
        isLoadingNext = false
    }
    
    func getLoadedChapterIds() -> [ChapterID] {
        return chapters.compactMap { chapter in
            loadedChapters.keys.contains(chapter.id) ? chapter.id : nil
        }
    }
}

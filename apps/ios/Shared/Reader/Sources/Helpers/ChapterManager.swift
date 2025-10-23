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
    
    // cache management
    private var cache: [ChapterID: ChapterData] = [:]
    private var loadedChapterIds: [ChapterID] = [] // maintains insertion order
    private var nextCache: [ChapterID: AnyReadableChapter] = [:] // caches next chapter lookup
    private var prevCache: [ChapterID: AnyReadableChapter] = [:] // caches prev chapter lookup
    
    // loading state
    private var loadingChapters: Set<ChapterID> = []
    private var isLoadingPrevious = false
    private var isLoadingNext = false
    
    struct ChapterData {
        let id: ChapterID
        let pages: [String]
        let loadedAt: Date
    }
    
    init(
        chapters: [AnyReadableChapter],
        fetchPages: @escaping @Sendable (ChapterID) async throws -> [String]
    ) {
        self.chapters = chapters
        self.fetchPages = fetchPages
        print("[ChapterManager] Initialized with \(chapters.count) chapters")
    }
    
    // MARK: - Cache Management
    
    func isChapterLoaded(_ chapterId: ChapterID) -> Bool {
        let loaded = cache[chapterId] != nil
        print("[ChapterManager] Chapter \(String(describing: chapterId)) loaded: \(loaded)")
        return loaded
    }
    
    func isChapterLoading(_ chapterId: ChapterID) -> Bool {
        return loadingChapters.contains(chapterId)
    }
    
    func getChapterData(_ chapterId: ChapterID) -> ChapterData? {
        return cache[chapterId]
    }
    
    func getLoadedChapters() -> [(id: ChapterID, pages: [String])] {
        // return in order they were loaded
        return loadedChapterIds.compactMap { id in
            guard let data = cache[id] else { return nil }
            return (id: data.id, pages: data.pages)
        }
    }
    
    func getLoadedChapterIds() -> [ChapterID] {
        return loadedChapterIds
    }
    
    func allImageURLs(orderedBy chapterIds: [ChapterID]) -> [String] {
        return chapterIds.flatMap { cache[$0]?.pages ?? [] }
    }
    
    // MARK: - Chapter Loading
    
    func loadChapter(_ chapterId: ChapterID) async throws -> [String] {
        print("[ChapterManager] Loading chapter: \(String(describing: chapterId))")
        
        // check cache first
        if let data = cache[chapterId] {
            print("[ChapterManager] Chapter found in cache")
            return data.pages
        }
        
        // check if already loading
        if loadingChapters.contains(chapterId) {
            print("[ChapterManager] Chapter already loading, waiting...")
            // wait for existing load to complete
            while loadingChapters.contains(chapterId) {
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
            // return cached result
            if let data = cache[chapterId] {
                return data.pages
            }
            throw ReaderError.invalidState
        }
        
        // mark as loading
        loadingChapters.insert(chapterId)
        
        do {
            let pages = try await fetchPages(chapterId)
            
            // cache the result
            let data = ChapterData(
                id: chapterId,
                pages: pages,
                loadedAt: Date()
            )
            cache[chapterId] = data
            
            // maintain order - always append for now, will be reordered when getting all URLs
            if !loadedChapterIds.contains(chapterId) {
                loadedChapterIds.append(chapterId)
            }
            
            loadingChapters.remove(chapterId)
            print("[ChapterManager] Chapter loaded successfully with \(pages.count) pages")
            return pages
            
        } catch {
            loadingChapters.remove(chapterId)
            print("[ChapterManager] Failed to load chapter: \(error)")
            throw error
        }
    }
    
    func getAllImageURLsInOrder() -> [String] {
        // sort loaded chapters by their position in the original chapter list
        let sortedIds = loadedChapterIds.sorted { id1, id2 in
            guard let index1 = chapters.firstIndex(where: { $0.id == id1 }),
                  let index2 = chapters.firstIndex(where: { $0.id == id2 }) else {
                return false
            }
            return index1 < index2
        }
        
        return sortedIds.flatMap { cache[$0]?.pages ?? [] }
    }
    
    // MARK: - Navigation Helpers
    
    func getChapter(after chapter: ChapterID) -> AnyReadableChapter? {
        // check cache first
        if let cached = nextCache[chapter] {
            return cached
        }
        
        guard let index = chapters.firstIndex(where: { $0.id == chapter }),
              index < chapters.count - 1 else {
            return nil
        }
        
        let next = chapters[index + 1]
        nextCache[chapter] = next
        return next
    }
    
    func getChapter(before chapter: ChapterID) -> AnyReadableChapter? {
        // check cache first
        if let cached = prevCache[chapter] {
            return cached
        }
        
        guard let index = chapters.firstIndex(where: { $0.id == chapter }),
              index > 0 else {
            return nil
        }
        
        let prev = chapters[index - 1]
        prevCache[chapter] = prev
        return prev
    }
    
    // MARK: - Loading State Management
    
    func canLoadPrevious(current: ChapterID, previous: AnyReadableChapter?) -> Bool {
        guard !isLoadingPrevious,
              let previous = previous,
              !isChapterLoaded(previous.id),
              !isChapterLoading(previous.id) else {
            return false
        }
        return true
    }
    
    func canLoadNext(current: ChapterID, next: AnyReadableChapter?) -> Bool {
        guard !isLoadingNext,
              let next = next,
              !isChapterLoaded(next.id),
              !isChapterLoading(next.id) else {
            return false
        }
        return true
    }
    
    func startLoadingPrevious() {
        isLoadingPrevious = true
        print("[ChapterManager] Started loading previous chapter")
    }
    
    func finishLoadingPrevious() {
        isLoadingPrevious = false
        print("[ChapterManager] Finished loading previous chapter")
    }
    
    func startLoadingNext() {
        isLoadingNext = true
        print("[ChapterManager] Started loading next chapter")
    }
    
    func finishLoadingNext() {
        isLoadingNext = false
        print("[ChapterManager] Finished loading next chapter")
    }
    
    // MARK: - Cache Cleanup
    
    func clearCache() {
        cache.removeAll()
        loadedChapterIds.removeAll()
        nextCache.removeAll()
        prevCache.removeAll()
        loadingChapters.removeAll()
        isLoadingPrevious = false
        isLoadingNext = false
        print("[ChapterManager] Cache cleared")
    }
}

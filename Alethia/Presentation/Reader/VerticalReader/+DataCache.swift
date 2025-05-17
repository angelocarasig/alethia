//
//  +DataCache.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation
import OrderedCollections

final actor ReaderDataCache {
    var cache: [Slug: [Page]] = [:]
    var chapters: OrderedSet<ChapterExtended> = []
    
    func setChapters(_ items: [ChapterExtended]) {
        chapters = OrderedSet(items)
    }
    
    func get(_ key: Slug) -> [Page]? {
        cache[key]
    }
    
    func getContentCount(_ key: String) -> Int {
        cache[key]?.count ?? 0
    }
    
    func update(chapter: ChapterExtended, pages: [Page]) {
        cache.updateValue(pages, forKey: chapter.chapter.slug)
    }
    
    func prepare(_ key: Slug) -> [ReaderPanel]? {
        guard let pages = cache[key],
              let chapter = pages.first?.chapter,
              let index = chapters.firstIndex(where: { $0.chapter == chapter }) else {
            // TODO:
            print("target chapter was not found")
            return nil
        }
        
        var objects: [ReaderPanel] = []
        
        // If first chapter, add 'no previous chapter' transition
        if index == 0 {
            let transition = Transition(from: chapter, to: nil, type: .previous)
            objects.append(.transition(transition))
        }
        
        let panelPages = pages.map { ReaderPanel.page($0) }
        objects.append(contentsOf: panelPages)
        
        // add transition to next
        let next = nextChapter(for: chapter)
        
        objects.append(.transition(
            Transition(from: chapter, to: next?.chapter, type: .next, pageCount: panelPages.count)
        ))
        
        return objects
    }
}

// MARK: Utils

extension ReaderDataCache {
    func nextChapter(for chapter: Chapter) -> ChapterExtended? {
        // Find the index of the current chapter in the ordered set
        guard let index = chapters.firstIndex(where: { $0.chapter == chapter }) else {
            return nil
        }
        
        // Check if there is a next chapter
        let nextIndex = index + 1
        guard nextIndex < chapters.count else {
            return nil // No next chapter
        }
        
        // Return the next chapter
        return chapters[nextIndex]
    }
    
    func previousChapter(for chapter: Chapter) -> ChapterExtended? {
        // Find the index of the current chapter in the ordered set
        guard let index = chapters.firstIndex(where: { $0.chapter == chapter }) else {
            return nil
        }
        
        // Check if there is a prev chapter
        let prevIndex = index - 1
        guard prevIndex >= 0 else {
            return nil
        }
        
        return chapters[prevIndex]
    }
}

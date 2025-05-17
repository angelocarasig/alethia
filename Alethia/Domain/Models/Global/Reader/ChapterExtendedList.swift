//
//  ChapterExtendedList.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

class ChapterExtendedListNode {
    var chapter: ChapterExtended
    var next: ChapterExtendedListNode?
    var prev: ChapterExtendedListNode?
    
    init(chapter: ChapterExtended) {
        self.chapter = chapter
        self.next = nil
        self.prev = nil
    }
}

class ChapterExtendedList {
    private(set) var head: ChapterExtendedListNode?
    private(set) var tail: ChapterExtendedListNode?
    private var nodeMap: [String: ChapterExtendedListNode] = [:]
    
    init(chapters: [ChapterExtended], sortBy: ((ChapterExtended, ChapterExtended) -> Bool)? = nil) {
        let sortedChapters: [ChapterExtended]
        
        if let sortBy = sortBy {
            sortedChapters = chapters.sorted(by: sortBy)
        } else {
            // default ordered from highest to lowest
            sortedChapters = chapters.sorted { $0.chapter.number > $1.chapter.number }
        }
        
        guard !sortedChapters.isEmpty else { return }
        
        // Create the first node
        let firstNode = ChapterExtendedListNode(chapter: sortedChapters[0])
        head = firstNode
        nodeMap[sortedChapters[0].id] = firstNode
        
        var currentNode = firstNode
        
        // Connect the rest of the nodes
        for i in 1..<sortedChapters.count {
            let newNode = ChapterExtendedListNode(chapter: sortedChapters[i])
            newNode.prev = currentNode
            currentNode.next = newNode
            nodeMap[sortedChapters[i].id] = newNode
            
            currentNode = newNode
        }
        
        // Update the tail
        tail = currentNode
    }
    
    var isEmpty: Bool {
        return head == nil
    }
    
    var count: Int {
        return nodeMap.count
    }
    
    func getChapterById(forChapterSlug slug: Slug) -> ChapterExtendedListNode? {
        return nodeMap[slug]
    }
    
    func nextChapter(for chapterSlug: Slug) -> ChapterExtended? {
        guard let node = nodeMap[chapterSlug], let next = node.next else {
            return nil
        }
        return next.chapter
    }
    
    func previousChapter(for chapterSlug: Slug) -> ChapterExtended? {
        guard let node = nodeMap[chapterSlug], let prev = node.prev else {
            return nil
        }
        return prev.chapter
    }
    
    func getAllChapters() -> [ChapterExtended] {
        var result: [ChapterExtended] = []
        var current = head
        
        while let node = current {
            result.append(node.chapter)
            current = node.next
        }
        
        return result
    }
    
    func clear() {
        head = nil
        tail = nil
        nodeMap.removeAll()
    }
}

extension ChapterExtendedList {
    // Find a chapter node that matches a predicate
    func findChapter(where predicate: (ChapterExtended) -> Bool) -> ChapterExtended? {
        var current = head
        
        while let node = current {
            if predicate(node.chapter) {
                return node.chapter
            }
            current = node.next
        }
        
        return nil
    }
    
    // Return a sublist between two chapter IDs (inclusive)
    func chaptersRange(from startSlug: Slug, to endSlug: Slug) -> [ChapterExtended]? {
        guard let startNode = nodeMap[startSlug], let endNode = nodeMap[endSlug] else {
            return nil
        }
        
        var result: [ChapterExtended] = []
        var current: ChapterExtendedListNode? = startNode
        
        // Check if endNode comes after startNode
        var isValid = false
        var check: ChapterExtendedListNode? = startNode
        while let node = check {
            if node === endNode {
                isValid = true
                break
            }
            check = node.next
        }
        
        if !isValid {
            return nil // endNode doesn't come after startNode
        }
        
        // Collect chapters between startNode and endNode (inclusive)
        while let node = current {
            result.append(node.chapter)
            
            if node === endNode {
                break
            }
            
            current = node.next
        }
        
        return result
    }
}

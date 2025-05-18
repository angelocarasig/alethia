//
//  ReaderChapterList.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

final class ReaderChapterListNode {
    var chapter: ChapterExtended
    var next: ReaderChapterListNode?
    var prev: ReaderChapterListNode?
    
    init(chapter: ChapterExtended) {
        self.chapter = chapter
        self.next = nil
        self.prev = nil
    }
}

final class ReaderChapterList {
    private(set) var head: ReaderChapterListNode?
    private(set) var tail: ReaderChapterListNode?
    private var slugMap: [Slug: ReaderChapterListNode] = [:]
    
    init(chapters: [ChapterExtended], sortBy: ((ChapterExtended, ChapterExtended) -> Bool)? = nil) {
        let sortedChapters: [ChapterExtended]
        
        if let sortBy = sortBy {
            sortedChapters = chapters.sorted(by: sortBy)
        } else {
            // default ordered from highest to lowest
            sortedChapters = chapters.sorted { $0.chapter.number < $1.chapter.number }
        }
        
        guard !sortedChapters.isEmpty else { return }
        
        // Create the first node
        let firstNode = ReaderChapterListNode(chapter: sortedChapters[0])
        head = firstNode
        slugMap[sortedChapters[0].chapter.slug] = firstNode
        
        var currentNode = firstNode
        
        // Connect the rest of the nodes
        for i in 1..<sortedChapters.count {
            let newNode = ReaderChapterListNode(chapter: sortedChapters[i])
            newNode.prev = currentNode
            currentNode.next = newNode
            slugMap[sortedChapters[i].chapter.slug] = newNode
            
            currentNode = newNode
        }
        
        // Update the tail
        tail = currentNode
    }
    
    var isEmpty: Bool {
        return head == nil
    }
    
    var count: Int {
        return slugMap.count
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
        slugMap.removeAll()
    }
}

// MARK: Searching
extension ReaderChapterList {
    func findNode(where predicate: (ChapterExtended) -> Bool) -> ReaderChapterListNode? {
        var current = head
        
        while let node = current {
            if predicate(node.chapter) {
                return node
            }
            current = node.next
        }
        
        return nil
    }
    
    var debugDescription: String {
        var result = "ReaderChapterList: [\n"
        var current = head
        var index = 0
        
        while let node = current {
            // Format each node with index, slug, and chapter title
            result += "  \(index): \(node.chapter.chapter.slug) - '\(node.chapter.chapter.title)'"
            
            // Add prev/next indicators
            var connections = [String]()
            if node.prev != nil {
                connections.append("prev: \(node.prev!.chapter.chapter.slug)")
            } else {
                connections.append("prev: nil")
            }
            
            if node.next != nil {
                connections.append("next: \(node.next!.chapter.chapter.slug)")
            } else {
                connections.append("next: nil")
            }
            
            result += " (\(connections.joined(separator: ", ")))\n"
            
            // Move to next node
            current = node.next
            index += 1
        }
        
        result += "Total Nodes: \(slugMap.count)\n]"
        
        // Add a traversal trace to verify connections
        result += "\n\nTraversal from head to tail:\n"
        current = head
        index = 0
        
        while let node = current {
            result += "  Step \(index): \(node.chapter.chapter.slug)"
            if node.next == nil {
                result += " (TAIL)"
            }
            result += "\n"
            
            current = node.next
            index += 1
        }
        
        return result
    }
}

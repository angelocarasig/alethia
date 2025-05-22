//
//  ChapterList.swift
//  Alethia
//
//  Created by Angelo Carasig on 22/5/2025.
//

import Foundation

final class ChapterListNode {
    var chapter: ChapterExtended
    var next: ChapterListNode?
    var previous: ChapterListNode?
    
    init(chapter: ChapterExtended) {
        self.chapter = chapter
    }
}

final class ChapterList {
    private var head: ChapterListNode?
    private var tail: ChapterListNode?
    private(set) var count: Int = 0
    
    init(chapters: [ChapterExtended]) {
        let sorted = chapters.sorted { $0.chapter.number < $1.chapter.number }
        for chapter in sorted {
            append(chapter)
        }
    }
    
    private func append(_ chapter: ChapterExtended) {
        let newNode = ChapterListNode(chapter: chapter)
        
        if tail == nil {
            // First node
            head = newNode
            tail = newNode
        } else {
            // Link to existing tail
            tail?.next = newNode
            newNode.previous = tail
            tail = newNode
        }
        
        count += 1
    }
    
    func findNode(for chapter: ChapterExtended) -> ChapterListNode? {
        var current = head
        while current != nil {
            if current?.chapter.chapter.id == chapter.chapter.id {
                return current
            }
            current = current?.next
        }
        return nil
    }
    
    func nextChapter(after chapter: ChapterExtended) -> ChapterExtended? {
        guard let node = findNode(for: chapter) else { return nil }
        return node.next?.chapter
    }
    
    func previousChapter(before chapter: ChapterExtended) -> ChapterExtended? {
        guard let node = findNode(for: chapter) else { return nil }
        return node.previous?.chapter
    }
    
    func hasNext(after chapter: ChapterExtended) -> Bool {
        guard let node = findNode(for: chapter) else { return false }
        return node.next != nil
    }
    
    func hasPrevious(before chapter: ChapterExtended) -> Bool {
        guard let node = findNode(for: chapter) else { return false }
        return node.previous != nil
    }
}

// MARK: - Sequence Conformance

extension ChapterList: Sequence {
    func toArray() -> [ChapterExtended] {
        var chapters: [ChapterExtended] = []
        var current = head
        
        while current != nil {
            chapters.append(current!.chapter)
            current = current?.next
        }
        
        return chapters
    }
    
    func makeIterator() -> ChapterListIterator {
        return ChapterListIterator(head: head)
    }
}

struct ChapterListIterator: IteratorProtocol {
    private var current: ChapterListNode?
    
    init(head: ChapterListNode?) {
        self.current = head
    }
    
    mutating func next() -> ChapterExtended? {
        guard let node = current else { return nil }
        current = node.next
        return node.chapter
    }
}

// MARK: - CustomStringConvertible

extension ChapterList: CustomStringConvertible {
    var description: String {
        let chapters = toArray().map { $0.chapter.toString() }
        return "ChapterList: [\(chapters.joined(separator: ", "))]"
    }
}

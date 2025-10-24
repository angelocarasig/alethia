//
//  AnyReaderDataSource.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// type-erased wrapper for ReaderDataSource
internal final class AnyReaderDataSource: @unchecked Sendable {
    private let _chapters: [AnyReadableChapter]
    private let _fetchPages: @Sendable (ChapterID) async throws -> [String]
    
    init<DS: ReaderDataSource>(_ dataSource: DS) {
        self._chapters = dataSource.chapters.map { AnyReadableChapter($0) }
        self._fetchPages = { chapterId in
            // find the original typed chapter to get its ID
            guard let anyChapter = dataSource.chapters.first(where: { ChapterID($0.id) == chapterId }) else {
                throw ReaderError.chapterNotFound
            }
            return try await dataSource.fetchPages(for: anyChapter.id)
        }
    }
    
    var chapters: [AnyReadableChapter] {
        return _chapters
    }
    
    func fetchPages(for chapterId: ChapterID) async throws -> [String] {
        return try await _fetchPages(chapterId)
    }
}

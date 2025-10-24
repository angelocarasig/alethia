//
//  ReaderDataSource.swift
//  Reader
//
//  Created by Angelo Carasig on 21/10/2025.
//

import Foundation

/// protocol for providing chapter data to the reader
public protocol ReaderDataSource<Chapter>: Sendable {
    
    associatedtype Chapter: ReadableChapter
    
    /// ordered list of chapters available for reading
    var chapters: [Chapter] { get }
    
    /// fetch image urls for a specific chapter
    /// - Parameter chapterId: unique identifier of the chapter
    /// - Returns: array of image url strings for the chapter
    /// - Throws: error if chapter cannot be fetched or no longer exists
    func fetchPages(for chapterId: Chapter.ID) async throws -> [String]
}

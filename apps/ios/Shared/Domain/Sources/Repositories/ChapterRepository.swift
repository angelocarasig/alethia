//
//  ChapterRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

public protocol ChapterRepository: Sendable {
    /// fetches chapter content urls for a given chapter
    /// - parameter chapterId: the id of the chapter to fetch contents for
    /// - returns: array of image urls in reading order
    func getChapterContents(chapterId: Int64) async throws -> [String]
}

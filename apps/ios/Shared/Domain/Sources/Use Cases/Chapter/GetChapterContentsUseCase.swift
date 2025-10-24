//
//  GetChapterContentsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

public protocol GetChapterContentsUseCase: Sendable {
    /// fetches chapter content urls
    /// - parameter chapterId: the id of the chapter
    /// - returns: array of image urls in reading order
    func execute(chapterId: Int64) async throws -> [String]
}

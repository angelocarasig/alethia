//
//  ReaderDataSource.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Domain
import Composition
import Reader

struct AlethiaReaderDataSource: ReaderDataSource {
    typealias Chapter = Domain.Chapter
    
    var chapters: [Domain.Chapter]
    
    private let getChapterContentsUseCase: GetChapterContentsUseCase
    
    init(chapters: [Domain.Chapter], getChapterContentsUseCase: GetChapterContentsUseCase) {
        self.chapters = chapters
        self.getChapterContentsUseCase = getChapterContentsUseCase
    }
    
    func fetchPages(for chapterId: Int64) async throws -> [String] {
        do {
            return try await getChapterContentsUseCase.execute(chapterId: chapterId)
        } catch {
            // log error for debugging
            print("Failed to fetch pages for chapter \(chapterId): \(error.localizedDescription)")
            throw error
        }
    }
}

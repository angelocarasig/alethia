//
//  ChapterRepositoryImpl.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

final class ChapterRepositoryImpl {
    private let local: ChapterLocalDataSource
    private let remote: ChapterRemoteDataSource
    
    init(local: ChapterLocalDataSource, remote: ChapterRemoteDataSource) {
        self.local = local
        self.remote = remote
    }
}

extension ChapterRepositoryImpl: ChapterRepository {
    func getChapterContents(chapter: Chapter) async throws -> [String] {
        return try await remote.getChapterContents(chapter: chapter)
    }
}

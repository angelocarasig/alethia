//
//  ChapterRepository.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import Foundation
import Combine

protocol ChapterRepository {
    func getChapterContents(chapter: Chapter) async throws -> [String]
    
    func updateChapterProgress(chapter: Chapter, newProgress: Double) throws -> Void
    
    func markChapterRead(chapter: Chapter) throws -> Void
}

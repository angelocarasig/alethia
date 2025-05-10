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
    
    // To be called on reader exit
    func updateChapterProgress(chapter: Chapter, newProgress: Double) throws -> Void
    
    // To be called when going to next chapter
    func markChapterRead(chapter: Chapter) throws -> Void
}

//
//  ChapterLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation
import Domain
import GRDB

internal protocol ChapterLocalDataSource: Sendable {
    /// fetches chapter metadata needed for building request url
    /// - parameter chapterId: the chapter id
    /// - returns: tuple containing chapter slug, manga id, source slug, and host url
    func getChapterRequestInfo(chapterId: Int64) async throws -> (chapterSlug: String, mangaId: Int64, sourceSlug: String, hostUrl: URL)
}

internal final class ChapterLocalDataSourceImpl: ChapterLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getChapterRequestInfo(chapterId: Int64) async throws -> (chapterSlug: String, mangaId: Int64, sourceSlug: String, hostUrl: URL) {
        do {
            return try await database.reader.read { db in
                // fetch chapter
                guard let chapter = try ChapterRecord.fetchOne(db, key: ChapterRecord.ID(rawValue: chapterId)) else {
                    throw StorageError.recordNotFound(table: "chapter", id: String(chapterId))
                }
                
                // fetch origin through chapter
                guard let origin = try chapter.origin.fetchOne(db) else {
                    throw StorageError.recordNotFound(table: "origin", id: "unknown")
                }
                
                // fetch manga through origin
                guard let manga = try origin.manga.fetchOne(db) else {
                    throw StorageError.recordNotFound(table: "manga", id: "unknown")
                }
                
                // fetch source through origin
                guard let sourceId = origin.sourceId else {
                    throw StorageError.recordNotFound(table: "source", id: "nil sourceId")
                }
                
                guard let source = try SourceRecord.fetchOne(db, key: sourceId) else {
                    throw StorageError.recordNotFound(table: "source", id: String(sourceId.rawValue))
                }
                
                // fetch host through source
                guard let host = try source.host.fetchOne(db) else {
                    throw StorageError.recordNotFound(table: "host", id: "unknown")
                }
                
                guard let mangaId = manga.id else {
                    throw StorageError.recordNotFound(table: "manga", id: "nil after fetch")
                }
                
                return (
                    chapterSlug: chapter.slug,
                    mangaId: mangaId.rawValue,
                    sourceSlug: source.slug,
                    hostUrl: host.url
                )
            }
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "getChapterRequestInfo")
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.queryFailed(sql: "getChapterRequestInfo", error: error)
        }
    }
}

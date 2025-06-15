//
//  ChapterRepository.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Combine

public extension Domain.Repositories {
    /// Repository interface for chapter data operations.
    /// 
    /// Provides abstraction over chapter-related data sources, handling both
    /// local database operations and remote API interactions. This repository
    /// manages mostly chapter-domain specific functions which includes (not limited to):
    /// - reading progress
    /// - downloads
    /// - content retrieval
    protocol ChapterRepository {
        // MARK: - Local
        
        /// Updates reading progress for a chapter.
        ///
        /// Tracks how far the user has read through the chapter and optionally
        /// returns the chapter contents for continued reading.
        ///
        /// - Parameters:
        ///   - chapterId: The ID of the chapter to update
        ///   - newProgress: Progress value between 0.0 (unread) and 1.0 (completed)
        ///   - override: When `true`, allows progress to decrease (re-reading)/marking unread
        /// - Throws: Database error if update fails
        /// - Note: Also updates the manga's lastReadAt timestamp
        func updateChapterProgress(chapterId: Int64, newProgress: Double, override: Bool) throws -> Void
        
        /// Marks a chapter as fully read.
        ///
        /// Sets the chapter's progress to 1.0 and updates the manga's lastReadAt timestamp.
        ///
        /// - Parameter chapterId: The ID of the chapter to mark as read
        /// - Throws: Database error if the operation fails
        func markChapterRead(chapterId: Int64) throws -> Void
        
        /// Batch updates the read status for multiple chapters.
        ///
        /// Efficiently updates multiple chapters in a single transaction.
        ///
        /// - Parameters:
        ///   - chapterIds: Array of chapter IDs to update
        ///   - asRead: `true` to mark as read (progress = 1.0), `false` to mark as unread (progress = 0.0)
        /// - Throws: Database error if the operation fails
        func markAllChapters(chapterIds: [Int64], asRead: Bool) throws -> Void
        
        /// Removes the downloaded file for a chapter.
        ///
        /// Deletes the local CBZ file and clears the localPath reference.
        ///
        /// - Parameter chapterId: The ID of the chapter whose download to remove
        /// - Throws: `FilesystemError` if file deletion fails
        func removeChapterDownload(chapterId: Int64) throws -> Void
        
        /// Removes all downloaded chapters for a manga.
        ///
        /// Batch deletes all local chapter files for the specified manga.
        ///
        /// - Parameter mangaId: The ID of the manga whose downloads to remove
        /// - Throws: `FilesystemError` if deletion fails
        func removeAllChapterDownloads(mangaId: Int64) throws -> Void
        
        // MARK: - Remote
        
        /// Retrieves the page URLs or paths for a chapter.
        ///
        /// Returns local file paths if downloaded, otherwise fetches from remote source.
        ///
        /// - Parameters:
        ///   - chapterId: The ID of the chapter to retrieve
        ///   - forceRemote: When `true`, ignores local cache and fetches from source
        /// - Returns: Array of page URLs or local file paths
        /// - Throws: `ChapterError.notFound` if chapter doesn't exist, `NetworkError` for remote failures
        func getChapterContents(chapterId: Int64, forceRemote: Bool) async throws -> [String]
        
        /// Initiates download for a single chapter.
        ///
        /// Downloads chapter pages and creates a local CBZ archive.
        ///
        /// - Parameter chapterId: The ID of the chapter to download
        /// - Throws: `DownloadError` if download fails
        func downloadChapter(chapterId: Int64) throws -> Void
        
        /// Downloads all chapters for a manga.
        ///
        /// Queues all available chapters for download based on current
        /// manga settings (showAllChapters, showHalfChapters).
        ///
        /// - Parameter mangaId: The ID of the manga whose chapters to download
        /// - Throws: `DownloadError` if operation fails
        func downloadAllChapters(mangaId: Int64) throws -> Void
    }
}

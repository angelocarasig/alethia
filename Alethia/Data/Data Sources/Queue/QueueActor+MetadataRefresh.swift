//
//  QueueActor+MetadataRefresh.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation
import GRDB

// MARK: - Metadata Refresh
extension QueueActor {
    func refreshMetadata(
        mangaId: Int64,
        continuation: AsyncStream<QueueOperationState>.Continuation
    ) async {
        do {
            // Step 1: Fetch data from all origins (10% - 80%)
            continuation.yield(.ongoing(0.1))
            
            let detailDTOs = try await fetchMangaOriginDetails(mangaId: mangaId) { progress in
                continuation.yield(.ongoing(0.1 + (0.7 * progress)))
            }
            
            // Step 2: Update metadata in database (80% - 95%)
            continuation.yield(.ongoing(0.85))
            
            for detailDTO in detailDTOs {
                try await updateMangaMetadata(mangaId: mangaId, payload: detailDTO)
            }
            
            // Step 3: Update refresh timestamp (95% - 100%)
            continuation.yield(.ongoing(0.95))
            
            try await updateMangaLastRefreshed(mangaId: mangaId)
            
            continuation.yield(.ongoing(1.0))
            continuation.yield(.completed)
            
        } catch {
            continuation.yield(.failed(error))
        }
    }
}

// MARK: - Private Helpers
extension QueueActor {
    func fetchMangaOriginDetails(
        mangaId: Int64,
        onProgress: @escaping (Double) -> Void
    ) async throws -> [DetailDTO] {
        // get the manga
        let manga: Manga = try await DatabaseProvider.shared.reader.read { db in
            guard let result = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            return result
        }
        
        // Get valid origins with their fetch URLs
        let validOrigins = try await getValidOrigins(for: manga)
        
        guard !validOrigins.isEmpty else {
            throw OriginError.notFound
        }
        
        // Fetch data from all origins concurrently
        let totalOrigins = validOrigins.count
        var completedCount = 0
        
        return try await withThrowingTaskGroup(of: DetailDTO.self) { group in
            // Add tasks for each origin
            for (originExtended, fetchUrl) in validOrigins {
                group.addTask {
                    do {
                        let detailDTO = try await self.fetchMangaDetail(from: fetchUrl)
                        print("✅ Successfully fetched data for origin: \(originExtended.origin.slug)")
                        return detailDTO
                    } catch {
                        print("❌ Failed to fetch data for origin \(originExtended.origin.slug): \(error)")
                        throw error
                    }
                }
            }
            
            // Collect results and report progress
            var results: [DetailDTO] = []
            for try await detailDTO in group {
                results.append(detailDTO)
                completedCount += 1
                
                let progress = Double(completedCount) / Double(totalOrigins)
                onProgress(progress)
            }
            
            return results
        }
    }
    
    func getValidOrigins(for manga: Manga) async throws -> [(OriginExtended, URL)] {
        return try await DatabaseProvider.shared.reader.read { db in
            let origins = try manga.originsExtended.fetchAll(db)
            
            return try origins.compactMap { originExtended -> (OriginExtended, URL)? in
                guard let source = originExtended.source,
                      let host = try Host.fetchOne(db, key: source.hostId)
                else {
                    print("⚠️ Skipping detached origin: \(originExtended.origin.slug)")
                    return nil
                }
                
                /// skip disabled sources
                guard !source.disabled else {
                    return nil
                }
                
                guard let fetchUrl = URL.appendingPaths(
                    host.baseUrl,
                    source.path,
                    "manga",
                    originExtended.origin.slug
                ) else {
                    print("⚠️ Failed to build URL for origin: \(originExtended.origin.slug)")
                    return nil
                }
                
                return (originExtended, fetchUrl)
            }
        }
    }
    
    func fetchMangaDetail(from url: URL) async throws -> DetailDTO {
        let networkService = NetworkService()
        return try await networkService.request(url: url)
    }
    
    func updateMangaMetadata(mangaId: Int64, payload: DetailDTO) async throws {
        try await DatabaseProvider.shared.writer.write { db in
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            print("📝 Updating metadata for manga \(mangaId) from payload: \(payload.manga.title)")
            
            guard let origin = try Origin
                .filter(Origin.Columns.mangaId == mangaId)
                .filter(Origin.Columns.slug == payload.origin.slug)
                .fetchOne(db) else {
                print("⚠️ Could not find origin for payload: \(payload.origin.slug)")
                return
            }
            
            // Update related entities
            try Self.updateTitles(payload.manga.alternativeTitles, mangaId: mangaId, db: db)
            try Self.updateCovers(payload.origin.covers, mangaId: mangaId, db: db)
            try Self.updateAuthors(payload.manga.authors, mangaId: mangaId, db: db)
            try Self.updateTags(payload.manga.tags, mangaId: mangaId, db: db)
            try Self.updateChapters(payload.chapters, originId: origin.id!, db: db)
            try Self.updateMangaUpdatedAt(mangaId: mangaId, db: db)
        }
    }
    
    func updateMangaLastRefreshed(mangaId: Int64) async throws {
        try await DatabaseProvider.shared.writer.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.updatedAt = Date()
            try manga.update(db)
        }
    }
}

// MARK: - Entity Update Helpers
extension QueueActor {
    static func updateTitles(_ newTitles: [String], mangaId: Int64, db: Database) throws {
        let existingTitles = Set(try Title
            .filter(Title.Columns.mangaId == mangaId)
            .fetchAll(db)
            .map(\.title))
        
        for title in newTitles where !existingTitles.contains(title) {
            try Title(title: title, mangaId: mangaId).insert(db)
            print("  ➕ Added title: \(title)")
        }
    }
    
    static func updateCovers(_ newCoverUrls: [String], mangaId: Int64, db: Database) throws {
        guard !newCoverUrls.isEmpty else { return }
        
        let existingCoverUrls = Set(try Cover
            .filter(Cover.Columns.mangaId == mangaId)
            .fetchAll(db)
            .map(\.url))
        
        for (_, coverUrl) in newCoverUrls.enumerated() where !existingCoverUrls.contains(coverUrl) {
            // Deactivate all existing covers
            try Cover
                .filter(Cover.Columns.mangaId == mangaId)
                .updateAll(db, Cover.Columns.active.set(to: false))
            
            // Add new cover and set it as active
            try Cover(
                active: true,
                url: coverUrl,
                path: coverUrl,
                mangaId: mangaId
            ).insert(db)
            print("  ➕ Added cover: \(coverUrl) (set as active)")
        }
    }
    
    static func updateAuthors(_ newAuthorNames: [String], mangaId: Int64, db: Database) throws {
        let existingAuthorNames = Set(try Author
            .joining(required: Author.mangaAuthor.filter(MangaAuthor.Columns.mangaId == mangaId))
            .fetchAll(db)
            .map(\.name))
        
        for authorName in newAuthorNames where !existingAuthorNames.contains(authorName) {
            let author = try Author.findOrCreate(db, instance: Author(name: authorName))
            
            guard let authorId = author.id else { continue }
            
            try MangaAuthor(authorId: authorId, mangaId: mangaId).insert(db, onConflict: .ignore)
            print("  ➕ Added author: \(authorName)")
        }
    }
    
    static func updateTags(_ newTagNames: [String], mangaId: Int64, db: Database) throws {
        let existingTagNames = Set(try Tag
            .joining(required: Tag.mangaTag.filter(MangaTag.Columns.mangaId == mangaId))
            .fetchAll(db)
            .map(\.name))
        
        for tagName in newTagNames where !existingTagNames.contains(tagName) {
            let tag = try Tag.findOrCreate(db, instance: Tag(name: tagName))
            
            guard let tagId = tag.id else {
                throw ApplicationError.internalError
            }
            
            try MangaTag(tagId: tagId, mangaId: mangaId).insert(db)
            print("  ➕ Added tag: \(tagName)")
        }
    }
    
    static func updateMangaUpdatedAt(mangaId: Int64, db: Database) throws {
        let sql = """
            SELECT MAX(c.date) as latestDate
            FROM chapter c
            JOIN origin o ON c.originId = o.id
            WHERE o.mangaId = ?
            """
        
        guard let latestDate = try Date.fetchOne(db, sql: sql, arguments: [mangaId]) else {
            return
        }
        
        guard var manga = try Manga.fetchOne(db, key: mangaId) else {
            throw MangaError.notFound
        }
        
        manga.updatedAt = latestDate
        try manga.update(db)
    }
    
    static func updateChapters(_ newChapters: [ChapterDTO], originId: Int64, db: Database) throws {
        guard !newChapters.isEmpty else { return }
        
        // Get existing chapter slugs for this origin
        let existingChapterSlugs = Set(try Chapter
            .filter(Chapter.Columns.originId == originId)
            .fetchAll(db)
            .map(\.slug))
        
        // IMPORTANT: Filter out chapters that already exist BEFORE processing scanlators
        let chaptersToInsert = newChapters.filter { !existingChapterSlugs.contains($0.slug) }
        
        // If no new chapters to insert, return early
        guard !chaptersToInsert.isEmpty else { return }
        
        // Group ONLY the chapters that will be inserted by scanlator
        let chaptersByScanlator = Dictionary(grouping: chaptersToInsert) { $0.scanlator }
        
        // Get existing scanlators for this origin
        let existingScanlators = try Scanlator
            .filter(Scanlator.Columns.originId == originId)
            .order(Scanlator.Columns.priority.asc)
            .fetchAll(db)
        
        var nextPriority = existingScanlators.last?.priority ?? -1
        
        // Process each scanlator group (only for chapters that will actually be inserted)
        for (scanlatorName, chapters) in chaptersByScanlator {
            // Try to find existing scanlator for this origin
            let existingScanlator = existingScanlators.first { $0.name == scanlatorName }
            
            let scanlator: Scanlator
            if let existing = existingScanlator {
                scanlator = existing
            } else {
                // Create new scanlator with next available priority
                nextPriority += 1
                var newScanlator = Scanlator(
                    originId: originId,
                    name: scanlatorName,
                    priority: nextPriority
                )
                newScanlator = try newScanlator.insertAndFetch(db)
                scanlator = newScanlator
                print("  ➕ Added new scanlator: \(scanlatorName)")
            }
            
            // Insert new chapters for this scanlator
            guard let scanlatorId = scanlator.id else { continue }
            
            for chapterDTO in chapters {
                try Chapter(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    title: chapterDTO.title,
                    slug: chapterDTO.slug,
                    number: chapterDTO.number,
                    date: Date.javascriptDate(chapterDTO.date)
                ).insert(db)
                print("  ➕ Added chapter: \(chapterDTO.number) - \(chapterDTO.title)")
            }
        }
    }
}

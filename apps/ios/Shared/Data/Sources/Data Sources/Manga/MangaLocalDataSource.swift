//
//  MangaLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 6/10/2025.
//

import Foundation
import Domain
import GRDB
import Core

// MARK: - Data Bundle for Repository

internal struct MangaDataBundle {
    let manga: MangaRecord
    let authors: [AuthorRecord]
    let tags: [TagRecord]
    let covers: [CoverRecord]
    let alternativeTitles: [AlternativeTitleRecord]
    let origins: [OriginRecord]
    let sources: [OriginRecord.ID: (source: SourceRecord, host: HostRecord)]
    let chapters: [ChapterWithMetadata]
    let collections: [CollectionRecord]
}

internal struct ChapterWithMetadata {
    let chapter: ChapterRecord
    let scanlatorName: String
    let sourceIcon: URL?
}

// MARK: - Protocol

internal protocol MangaLocalDataSource: Sendable {
    func getAllManga(for entry: Entry) -> AsyncStream<[MangaDataBundle]>
    func getSourceAndHost(sourceId: Int64) async throws -> (source: SourceRecord, host: HostRecord)
    @discardableResult
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord
}

// MARK: - Implementation

internal final class MangaLocalDataSourceImpl: MangaLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getAllManga(for entry: Entry) -> AsyncStream<[MangaDataBundle]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { [weak self] db -> [MangaDataBundle] in
                guard let self = self else { return [] }
                
                do {
                    let mangaIds = try self.findMangaIds(for: entry, in: db)
                    
                    guard !mangaIds.isEmpty else {
                        return []
                    }
                    
                    let mangaRecords = try MangaRecord
                        .filter(mangaIds.contains(MangaRecord.Columns.id))
                        .fetchAll(db)
                    
                    var bundles: [MangaDataBundle] = []
                    
                    for mangaRecord in mangaRecords {
                        guard mangaRecord.id != nil else { continue }
                        
                        let authors = try mangaRecord.authors.fetchAll(db)
                        let tags = try mangaRecord.tags.fetchAll(db)
                        let covers = try mangaRecord.covers.fetchAll(db)
                        let alternativeTitles = try mangaRecord.alternativeTitles.fetchAll(db)
                        let origins = try mangaRecord.origins.fetchAll(db)
                        
                        // fetch sources and hosts for each origin
                        var sources: [OriginRecord.ID: (source: SourceRecord, host: HostRecord)] = [:]
                        for origin in origins {
                            if let originId = origin.id,
                               let sourceId = origin.sourceId,
                               let source = try? SourceRecord.fetchOne(db, key: sourceId),
                               let host = try? source.host.fetchOne(db) {
                                sources[originId] = (source: source, host: host)
                            }
                        }
                        
                        let chaptersWithMetadata = try self.fetchChaptersWithMetadata(
                            for: origins,
                            manga: mangaRecord,
                            in: db
                        )
                        
                        let collections = try mangaRecord.collections.fetchAll(db)
                        
                        let bundle = MangaDataBundle(
                            manga: mangaRecord,
                            authors: authors,
                            tags: tags,
                            covers: covers,
                            alternativeTitles: alternativeTitles,
                            origins: origins,
                            sources: sources,
                            chapters: chaptersWithMetadata,
                            collections: collections
                        )
                        
                        bundles.append(bundle)
                    }
                    
                    return bundles
                } catch {
#if DEBUG
                    print("error in getAllManga: \(error)")
#endif
                    return []
                }
            }
            
            let task = Task {
                do {
                    for try await mangaData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(mangaData)
                    }
                } catch {
#if DEBUG
                    print("observation error: \(error)")
#endif
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func getSourceAndHost(sourceId: Int64) async throws -> (source: SourceRecord, host: HostRecord) {
        try await database.reader.read { db in
            guard let source = try SourceRecord.fetchOne(db, key: SourceRecord.ID(rawValue: sourceId)) else {
                throw RepositoryError.mappingError(reason: "source not found")
            }
            
            guard let host = try source.host.fetchOne(db) else {
                throw RepositoryError.hostNotFound
            }
            
            return (source: source, host: host)
        }
    }
    
    @discardableResult
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord {
        return try await database.writer.write { db in
            var mangaRecord = MangaRecord(
                title: dto.title,
                synopsis: AttributedString(dto.synopsis)
            )
            mangaRecord.updatedAt = dto.updatedAt
            mangaRecord.lastFetchedAt = Date()
            
            try mangaRecord.insert(db)
            
            guard let mangaId = mangaRecord.id else {
                throw RepositoryError.mappingError(reason: "failed to get manga id after insert")
            }
            
            try self.batchInsertAuthors(dto.authors, mangaId: mangaId, db: db)
            try self.batchInsertTags(dto.tags, mangaId: mangaId, db: db)
            try self.batchInsertCovers(dto.covers, mangaId: mangaId, db: db)
            try self.batchInsertAlternativeTitles(dto.alternativeTitles, mangaId: mangaId, db: db)
            
            let origin = try self.insertOrigin(dto, mangaId: mangaId, sourceId: sourceId, db: db)
            
            if let originId = origin.id {
                try self.batchInsertChapters(chapters, originId: originId, db: db)
            }
            
            return mangaRecord
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func findMangaIds(for entry: Entry, in db: Database) throws -> [Int64] {
        if let mangaId = entry.mangaId {
            return [mangaId]
        }
        
        let idsBySlug = try OriginRecord
            .select(OriginRecord.Columns.mangaId)
            .filter(OriginRecord.Columns.slug == entry.slug)
            .distinct()
            .asRequest(of: Int64.self)
            .fetchAll(db)
        
        if !idsBySlug.isEmpty {
            return Array(Set(idsBySlug))
        }
        
        let idsByTitle = try MangaRecord
            .select(MangaRecord.Columns.id)
            .filter(MangaRecord.Columns.title == entry.title)
            .asRequest(of: Int64.self)
            .fetchAll(db)
        
        let idsByAltTitle = try AlternativeTitleRecord
            .select(AlternativeTitleRecord.Columns.mangaId)
            .filter(AlternativeTitleRecord.Columns.title == entry.title)
            .distinct()
            .asRequest(of: Int64.self)
            .fetchAll(db)
        
        return Array(Set(idsByTitle + idsByAltTitle))
    }
    
    private func fetchChaptersWithMetadata(
        for origins: [OriginRecord],
        manga: MangaRecord,
        in db: Database
    ) throws -> [ChapterWithMetadata] {
        let originIds = origins.compactMap(\.id)
        
        guard !originIds.isEmpty else { return [] }
        
        let chapters = try ChapterRecord
            .filter(originIds.contains(ChapterRecord.Columns.originId))
            .fetchAll(db)
        
        let filteredChapters = applyChapterFilters(
            chapters: chapters,
            manga: manga,
            db: db
        )
        
        var chaptersWithMetadata: [ChapterWithMetadata] = []
        
        for chapter in filteredChapters {
            let scanlator = try chapter.scanlator.fetchOne(db)
            let origin = try chapter.origin.fetchOne(db)
            let source = try origin?.source.fetchOne(db)
            
            chaptersWithMetadata.append(ChapterWithMetadata(
                chapter: chapter,
                scanlatorName: scanlator?.name ?? "Unknown",
                sourceIcon: source?.icon
            ))
        }
        
        return chaptersWithMetadata
    }
    
    private func applyChapterFilters(chapters: [ChapterRecord], manga: MangaRecord, db: Database) -> [ChapterRecord] {
        if manga.showAllChapters {
            return chapters.sorted { $0.number < $1.number }
        }
        
        var filtered = chapters
        
        if !manga.showHalfChapters {
            filtered = filtered.filter { chapter in
                chapter.number == Double(Int(chapter.number))
            }
        }
        
        let grouped = Dictionary(grouping: filtered) { $0.number }
        filtered = grouped.compactMap { (_, chapters) in
            chapters.first
        }
        
        return filtered.sorted { $0.number < $1.number }
    }
    
    private func batchInsertAuthors(_ authorNames: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for name in authorNames {
            var author = try AuthorRecord
                .filter(AuthorRecord.Columns.name == name)
                .fetchOne(db) ?? AuthorRecord(name: name)
            
            if author.id == nil {
                try author.insert(db)
            }
            
            if let authorId = author.id {
                try MangaAuthorRecord(mangaId: mangaId, authorId: authorId)
                    .insert(db, onConflict: .ignore)
            }
        }
    }
    
    private func batchInsertTags(_ tagNames: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for tagName in tagNames {
            let normalizedName = tagName.lowercased().replacingOccurrences(of: " ", with: "")
            
            var tag = try TagRecord
                .filter(TagRecord.Columns.normalizedName == normalizedName)
                .fetchOne(db) ?? TagRecord(
                    normalizedName: normalizedName,
                    displayName: tagName,
                    canonicalId: nil
                )
            
            if tag.id == nil {
                try tag.insert(db)
            }
            
            if let tagId = tag.id {
                try MangaTagRecord(mangaId: mangaId, tagId: tagId)
                    .insert(db, onConflict: .ignore)
            }
        }
    }
    
    private func batchInsertCovers(_ coverUrls: [String], mangaId: MangaRecord.ID, db: Database) throws {
        // save cover metadata to database
        for (index, coverURLString) in coverUrls.enumerated() {
            guard let coverURL = URL(string: coverURLString) else { continue }
            
            // for now, we'll use the remote url as the local path
            // kingfisher will handle caching automatically
            var coverRecord = CoverRecord(
                mangaId: mangaId,
                isPrimary: index == 0,
                localPath: coverURL,  // using remote url, kingfisher handles caching
                remotePath: coverURL
            )
            try coverRecord.insert(db)
        }
        
        #warning("TODO: Enable this behind a user preference flag for offline-only mode (like Spotify)")
        // saveCoversForOfflineMode(coverUrls: coverUrls, mangaId: mangaId)
    }

    // separate function for future offline-only mode
    private func saveCoversForOfflineMode(coverUrls: [String], mangaId: MangaRecord.ID) {
        let coversDirectory = Core.Constants.Paths.local
            .appending(path: String(mangaId.rawValue))
            .appendingPathComponent("covers", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(
                at: coversDirectory,
                withIntermediateDirectories: true
            )
            
            for (index, coverURLString) in coverUrls.enumerated() {
                guard let coverURL = URL(string: coverURLString) else { continue }
                
                let localCoverPath = coversDirectory.appendingPathComponent("\(index).jpg")
                
                // this would download and save locally for offline-only mode
                if let coverData = try? Data(contentsOf: coverURL) {
                    try? coverData.write(to: localCoverPath)
                }
            }
        } catch {
            // silently fail for offline saves
            print("Failed to save covers for offline mode: \(error)")
        }
    }
    
    private func batchInsertAlternativeTitles(_ titles: [String], mangaId: MangaRecord.ID, db: Database) throws {
        for title in titles {
            var altTitleRecord = AlternativeTitleRecord(
                mangaId: mangaId,
                title: title
            )
            try altTitleRecord.insert(db, onConflict: .ignore)
        }
    }
    
    private func insertOrigin(_ dto: MangaDTO, mangaId: MangaRecord.ID, sourceId: Int64, db: Database) throws -> OriginRecord {
        let existingOrigins = try OriginRecord
            .filter(OriginRecord.Columns.mangaId == mangaId)
            .fetchAll(db)
        
        let nextPriority = (existingOrigins.map(\.priority).max() ?? -1) + 1
        
        var origin = OriginRecord(
            mangaId: mangaId,
            sourceId: SourceRecord.ID(rawValue: sourceId),
            slug: dto.slug,
            url: dto.url,
            priority: nextPriority,
            classification: Classification(rawValue: dto.classification) ?? .Unknown,
            status: Status(rawValue: dto.publication) ?? .Unknown
        )
        
        try origin.insert(db)
        return origin
    }
    
    private func batchInsertChapters(_ chapters: [ChapterDTO], originId: OriginRecord.ID, db: Database) throws {
        let chaptersByScanlator = Dictionary(grouping: chapters) { $0.scanlator }
        
        let existingPriorities = try OriginScanlatorPriorityRecord
            .filter(OriginScanlatorPriorityRecord.Columns.originId == originId)
            .fetchAll(db)
        
        var nextPriority = existingPriorities.map(\.priority).max() ?? -1
        
        for (scanlatorName, chapterGroup) in chaptersByScanlator {
            var scanlator = try ScanlatorRecord
                .filter(ScanlatorRecord.Columns.name == scanlatorName)
                .fetchOne(db) ?? ScanlatorRecord(name: scanlatorName)
            
            if scanlator.id == nil {
                try scanlator.insert(db)
            }
            
            guard let scanlatorId = scanlator.id else { continue }
            
            let relationExists = existingPriorities.contains { $0.scanlatorId == scanlatorId }
            
            if !relationExists {
                nextPriority += 1
                var priority = OriginScanlatorPriorityRecord(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    priority: nextPriority
                )
                try priority.insert(db)
            }
            
            for chapterDTO in chapterGroup {
                var chapter = ChapterRecord(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    slug: chapterDTO.slug,
                    title: chapterDTO.title,
                    number: chapterDTO.number,
                    date: chapterDTO.date,
                    url: URL(string: chapterDTO.url)!,
                    language: LanguageCode(chapterDTO.language),
                    progress: 0,
                    lastReadAt: nil
                )
                try chapter.insert(db, onConflict: .ignore)
            }
        }
    }
}

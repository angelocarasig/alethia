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

internal protocol MangaLocalDataSource: Sendable {
    func getAllManga(for entry: Entry) -> AsyncStream<[(MangaRecord, [AuthorRecord], [TagRecord], [CoverRecord], [AlternativeTitleRecord], [OriginRecord], [ChapterRecord])]>
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord
}

internal final class MangaLocalDataSourceImpl: MangaLocalDataSource {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    func getAllManga(for entry: Entry) -> AsyncStream<[(MangaRecord, [AuthorRecord], [TagRecord], [CoverRecord], [AlternativeTitleRecord], [OriginRecord], [ChapterRecord])]> {
        AsyncStream { continuation in
            let observation = ValueObservation.tracking { db -> [(MangaRecord, [AuthorRecord], [TagRecord], [CoverRecord], [AlternativeTitleRecord], [OriginRecord], [ChapterRecord])] in
                // first, find the manga records using our matching strategies
                let mangaRecords = try self.findMangaRecords(for: entry, in: db)
                
                // for each manga, fetch all related data
                return try mangaRecords.map { manga in
                    guard let mangaId = manga.id else {
                        throw RepositoryError.mappingError(reason: "Manga ID is nil")
                    }
                    
                    let authors = try manga.authors.fetchAll(db)
                    let tags = try manga.tags.fetchAll(db)
                    let covers = try manga.covers.fetchAll(db)
                    let alternativeTitles = try manga.alternativeTitles.fetchAll(db)
                    let origins = try manga.origins.fetchAll(db)
                    let chapters = try manga.fetchChapters(from: db)
                    
                    return (manga, authors, tags, covers, alternativeTitles, origins, chapters)
                }
            }
            
            let task = Task {
                do {
                    for try await mangaData in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(mangaData)
                    }
                    continuation.finish()
                } catch {
                    print("Error observing manga: \(error)")
                    continuation.yield([])  // yield empty array on error
                    continuation.finish()
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    func saveManga(from dto: MangaDTO, chapters: [ChapterDTO], entry: Entry, sourceId: Int64) async throws -> MangaRecord {
        try await database.writer.write { db in
            // create manga record
            var mangaRecord = MangaRecord(
                title: dto.title,
                synopsis: AttributedString(dto.synopsis)
            )
            mangaRecord.updatedAt = dto.updatedAt
            mangaRecord.lastFetchedAt = Date()
            
            try mangaRecord.insert(db)
            
            guard let mangaId = mangaRecord.id else {
                throw RepositoryError.mappingError(reason: "Failed to get manga ID after insert")
            }
            
            // save authors
            for authorName in dto.authors {
                var author = try AuthorRecord
                    .filter(AuthorRecord.Columns.name == authorName)
                    .fetchOne(db) ?? AuthorRecord(name: authorName)
                
                if author.id == nil {
                    try author.insert(db)
                }
                
                if let authorId = author.id {
                    let mangaAuthor = MangaAuthorRecord(
                        mangaId: mangaId,
                        authorId: authorId
                    )
                    try mangaAuthor.insert(db)
                }
            }
            
            // save tags
            for tagName in dto.tags {
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
                    let mangaTag = MangaTagRecord(
                        mangaId: mangaId,
                        tagId: tagId
                    )
                    try mangaTag.insert(db)
                }
            }
            
            // save covers
            let coversDirectory = Core.Constants.Paths.local.appending(path: (String(mangaId.rawValue)))
                .appendingPathComponent("covers", isDirectory: true)
            try FileManager.default.createDirectory(
                at: coversDirectory,
                withIntermediateDirectories: true
            )
            
            for (index, coverURLString) in dto.covers.enumerated() {
                if let coverURL = URL(string: coverURLString) {
                    let localCoverPath = coversDirectory.appendingPathComponent("\(index).jpg")
                    
                    // download cover image
                    if let coverData = try? Data(contentsOf: coverURL) {
                        try? coverData.write(to: localCoverPath)
                    }
                    
                    var coverRecord = CoverRecord(
                        mangaId: mangaId,
                        isPrimary: index == 0,
                        localPath: localCoverPath,
                        remotePath: coverURL
                    )
                    try coverRecord.insert(db)
                }
            }
            
            // save alternative titles
            for altTitle in dto.alternativeTitles {
                var altTitleRecord = AlternativeTitleRecord(
                    mangaId: mangaId,
                    title: altTitle
                )
                try altTitleRecord.insert(db)
            }
            
            // save origin
            let classification = Classification(rawValue: dto.classification) ?? .Unknown
            let status = Status(rawValue: dto.publication) ?? .Unknown
            
            var originRecord = OriginRecord(
                mangaId: mangaId,
                sourceId: SourceRecord.ID(rawValue: sourceId),
                slug: entry.slug,
                url: dto.url,
                priority: 0,
                classification: classification,
                status: status
            )
            try originRecord.insert(db)
            
            guard let originId = originRecord.id else {
                throw RepositoryError.mappingError(reason: "Failed to get origin ID after insert")
            }
            
            // save chapters and scanlators
            for chapterDTO in chapters {
                // get or create scanlator
                var scanlator = try ScanlatorRecord
                    .filter(ScanlatorRecord.Columns.name == chapterDTO.scanlator)
                    .fetchOne(db) ?? ScanlatorRecord(name: chapterDTO.scanlator)
                
                if scanlator.id == nil {
                    try scanlator.insert(db)
                }
                
                guard let scanlatorId = scanlator.id else { continue }
                
                // create chapter
                var chapterRecord = ChapterRecord(
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
                try chapterRecord.insert(db)
            }
            
            return mangaRecord
        }
    }
    
    private func findMangaRecords(for entry: Entry, in db: Database) throws -> [MangaRecord] {
        // strategy 1: direct manga id lookup
        if let mangaId = entry.mangaId {
            guard let manga = try MangaRecord.fetchOne(db, key: MangaRecord.ID(rawValue: mangaId)) else {
                throw RepositoryError.mangaNotFound
            }
            return [manga]
        }
        
        // strategy 2: origin slug matching
        let mangaBySlug = try MangaRecord
            .joining(required: MangaRecord.origins
                .filter(OriginRecord.Columns.slug == entry.slug))
            .distinct()
            .fetchAll(db)
        
        if !mangaBySlug.isEmpty {
            return mangaBySlug
        }
        
        // strategy 3: exact title matching (using collation from schema)
        // check main titles - localizedCaseInsensitiveCompare handles the comparison
        let mangaByTitle = try MangaRecord
            .filter(MangaRecord.Columns.title == entry.title)
            .fetchAll(db)
        
        // check alternative titles - also uses localizedCaseInsensitiveCompare
        let mangaByAltTitle = try MangaRecord
            .joining(required: MangaRecord.alternativeTitles
                .filter(AlternativeTitleRecord.Columns.title == entry.title))
            .distinct()
            .fetchAll(db)
        
        // combine results and remove duplicates
        let allMatches = Array(Set(mangaByTitle + mangaByAltTitle))
        
        if allMatches.isEmpty {
            throw RepositoryError.mangaNotFound
        }
        
        return allMatches
    }
}

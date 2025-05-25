//
//  MangaLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import Combine
import GRDB

private extension LibraryDate {
    func apply<T>(to request: QueryInterfaceRequest<T>, column: Column) -> QueryInterfaceRequest<T> {
        switch self {
        case .none:
            return request
        case .before(let date):
            return request.filter(column <= date)
        case .after(let date):
            return request.filter(column >= date)
        case .between(let start, let end):
            return request.filter(column >= start).filter(column <= end)
        }
    }
}

final class MangaLocalDataSource {
    private let database: DatabaseWriter
    
    init(database: DatabaseWriter = DatabaseProvider.shared.writer) {
        self.database = database
    }
    
    func getLibrary(filters: LibraryFilters) -> AnyPublisher<[Entry], Error> {
        let search = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ValueObservation
            .tracking { [weak self] db -> [Entry] in
                guard let self = self else { return [] }
                
                var request = Manga
                    .entry
                    .filter(Manga.Columns.inLibrary)
                
                // Apply date filters
                request = filters.addedAt.apply(to: request, column: Manga.Columns.addedAt)
                request = filters.updatedAt.apply(to: request, column: Manga.Columns.updatedAt)
                
                // Apply publish status filter
                if !filters.publishStatus.isEmpty {
                    request = self.applyPublishStatusFilter(to: request, statuses: filters.publishStatus)
                }
                
                // Apply classification filter
                if !filters.classification.isEmpty {
                    request = self.applyClassificationFilter(to: request, classifications: filters.classification)
                }
                
                // Apply search filter
                if !search.isEmpty {
                    request = self.applySearchFilter(to: request, search: search)
                }
                
                // Apply sorting
                request = self.applySorting(to: request, type: filters.sortType, direction: filters.sortDirection)
                
                return try request.fetchAll(db)
            }
            .publisher(in: database, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func saveNewManga(payload: DetailDTO, with sourceId: Int64?) -> AnyPublisher<Detail, Error> {
        return Deferred {
            Future<Detail, Error> { [weak self] promise in
                guard let self = self else {
                    promise(.failure(MangaError.notFound))
                    return
                }
                
                do {
                    try self.database.write { db in
                        // Verify source exists
                        guard let source = try Source.filter(id: sourceId).fetchOne(db),
                              let sourceId = source.id else {
                            throw SourceError.notFound
                        }
                        
                        // Insert manga
                        var manga = Manga(title: payload.manga.title, synopsis: payload.manga.synopsis)
                        manga = try manga.insertAndFetch(db)
                        guard let mangaId = manga.id else {
                            throw MangaError.notFound
                        }
                        
                        // Insert related entities
                        try self.insertRelatedEntities(
                            for: payload,
                            mangaId: mangaId,
                            sourceId: sourceId,
                            db: db
                        )
                        
                        // Fetch the complete detail object
                        if let detail = try self.fetchDetailWithChapters(db: db, manga: manga) {
                            promise(.success(detail))
                        } else {
                            throw MangaError.notFound
                        }
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Never> {
        return ValueObservation.tracking { [weak self] db -> [Detail] in
            guard let self = self else { return [] }
            
            var details: [Detail] = []
            
            // First: fetch by ID - Exact match should return early
            if let manga = try Manga.fetchOne(db, key: entry.mangaId),
               let detail = try self.fetchDetailWithChapters(db: db, manga: manga) {
                return [detail]
            }
            
            // Alt: fetch by title
            let titleMatches = try self.findMangasByTitle(db: db, title: entry.title)
            
            for manga in titleMatches where !details.contains(where: { $0.manga.id == manga.id }) {
                if let detail = try self.fetchDetailWithChapters(db: db, manga: manga) {
                    details.append(detail)
                }
            }
            
            return details
            
            //            let manga = try Manga.fetchAll(db)
            //            return try manga.map { try self.fetchDetailWithChapters(db: db, manga: $0)! }
        }
        .publisher(in: database, scheduling: .immediate)
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
    
    func toggleMangaInLibrary(mangaId: Int64, newValue: Bool) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.inLibrary = newValue
            try manga.update(db)
        }
    }
    
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.orientation = newValue
            try manga.update(db)
        }
    }
    
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries {
        return try database.read { db in
            // Get the target manga to ensure it exists
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            // 1. Similar tags - manga that share tags with the target manga
            let withSimilarTags = try fetchSimilarTaggedManga(db: db, mangaId: mangaId)
            
            // 2. Same collection - manga in the same collections
            let fromSameCollection = try fetchSameCollectionManga(db: db, mangaId: mangaId)
            
            // 3. Same author - other works by the same authors
            let otherWorksByAuthor = try fetchSameAuthorManga(db: db, mangaId: mangaId)
            
            // 4. Same scanlator - other series by the same scanlators
            let otherSeriesByScanlator = try fetchSameScanlatorManga(db: db, mangaId: mangaId)
            
            return RecommendedEntries(
                withSimilarTags: withSimilarTags,
                fromSameCollection: fromSameCollection,
                otherWorksByAuthor: otherWorksByAuthor,
                otherSeriesByScanlator: otherSeriesByScanlator
            )
        }
    }
    
    func resolveMangaOrientation(detail: Detail) -> Orientation {
        //only resolve for default, otherwise just return the current one
        guard detail.manga.orientation == .Default else {
            return detail.manga.orientation
        }
        
        let tagMatchers: [String] = [
            "webtoon",
            "manhwa",
            "manhua",
            "longstrip",
            "vertical",
            "scroll",
            "scrolling",
            "webcomic",
            "digitalcomic",
            "mobilecomic",
            "korean",
            "chinese",
            "fullcolor",
            "colored",
            "oel",
            "tapas",
            "linewebtoon",
            "naver",
            "lezhin",
            "toomics",
        ]
        
        func sanitizer(_ text: String) -> String {
            return text.lowercased().filter { $0.isLetter && $0.isASCII }
        }
        
        let sanitizedTagMatchers = tagMatchers.map(sanitizer)
        
        if detail.tags.contains(where: { tag in
            sanitizedTagMatchers.contains(sanitizer(tag.name))
        }) {
            return .Infinite
        }
        
        return .LeftToRight
    }
}


// MARK: Private helpers

private extension MangaLocalDataSource {
    private func applyPublishStatusFilter(
        to request: QueryInterfaceRequest<Entry>,
        statuses: [PublishStatus]
    ) -> QueryInterfaceRequest<Entry> {
        guard !statuses.isEmpty else { return request }
        
        let statusValues = statuses.map { $0.rawValue }
        let placeholders = statusValues.map { _ in "?" }.joined(separator: ", ")
        
        return request.filter(
            literal: SQL(sql:
                """
                mangaId IN (
                    SELECT DISTINCT o.mangaId
                    FROM origin o
                    WHERE o.status IN (\(placeholders))
                    AND o.priority = (
                        SELECT MIN(o2.priority)
                        FROM origin o2
                        WHERE o2.mangaId = o.mangaId
                    )
                )
                """,
                         arguments: StatementArguments(statusValues)
                        )
        )
    }
    
    private func applyClassificationFilter(
        to request: QueryInterfaceRequest<Entry>,
        classifications: [Classification]
    ) -> QueryInterfaceRequest<Entry> {
        guard !classifications.isEmpty else { return request }
        
        let classificationValues = classifications.map { $0.rawValue }
        let placeholders = classificationValues.map { _ in "?" }.joined(separator: ", ")
        
        return request.filter(
            literal: SQL(sql:
                """
                mangaId IN (
                    SELECT DISTINCT o.mangaId
                    FROM origin o
                    WHERE o.classification IN (\(placeholders))
                    AND o.priority = (
                        SELECT MIN(o2.priority)
                        FROM origin o2
                        WHERE o2.mangaId = o.mangaId
                    )
                )
                """,
                         arguments: StatementArguments(classificationValues)
                        )
        )
    }
    
    private func applySearchFilter(
        to request: QueryInterfaceRequest<Entry>,
        search: String
    ) -> QueryInterfaceRequest<Entry> {
        // For Entry type queries, we need to use a raw SQL filter that checks both
        // the manga title and alternative titles
        return request.filter(
            sql: """
            (INSTR(LOWER(title), LOWER(?)) > 0 OR 
             EXISTS(
                SELECT 1 FROM title t 
                WHERE t.mangaId = manga.id 
                AND INSTR(LOWER(t.title), LOWER(?)) > 0
             ))
            """,
            arguments: [search, search]
        )
    }
    
    private func applySorting(
        to request: QueryInterfaceRequest<Entry>,
        type: LibrarySortType,
        direction: LibrarySortDirection
    ) -> QueryInterfaceRequest<Entry> {
        // For Entry requests, we need to map the sort columns appropriately
        let sortColumn: Column = {
            switch type {
            case .title:
                return Entry.Columns.title
            case .created, .added:
                // These would need SQL expressions if we need exact sorting
                // For now, defaulting to title as a basic implementation
                return Entry.Columns.title
            case .updated:
                return Entry.Columns.title
            }
        }()
        
        // XOR on title sort type
        let useAscending = (direction == .ascending) != (type == .title)
        
        return request.order(useAscending ? sortColumn.asc : sortColumn.desc)
    }
    
    private func findMangasByTitle(db: Database, title: String) throws -> [Manga] {
        var results: [Manga] = []
        var foundIds: Set<Int64> = []
        
        // 1. Find manga with matching main title
        let mainTitleMatches = try Manga
            .filter(Manga.Columns.title == title)
            .order(Manga.Columns.id.asc)  // Consistent ordering
            .fetchAll(db)
        
        for manga in mainTitleMatches {
            if let id = manga.id {
                results.append(manga)
                foundIds.insert(id)
            }
        }
        
        // 2. Find manga with matching alternative titles
        let altTitleMatches = try Manga
            .joining(required: Manga.titles.filter(Title.Columns.title == title))
            .order(Manga.Columns.id.asc)
            .fetchAll(db)
        
        for manga in altTitleMatches {
            if let id = manga.id, !foundIds.contains(id) {
                results.append(manga)
                foundIds.insert(id)
            }
        }
        
        // Return with main title matches first
        return results
    }
    
    private func fetchDetailWithChapters(db: Database, manga: Manga) throws -> Detail? {
        let titles: [Title] = try manga.titles.order(Title.Columns.title).fetchAll(db)
        let covers: [Cover] = try manga.covers.fetchAll(db)
        let authors: [Author] = try manga.authors.fetchAll(db)
        let tags: [Tag] = try manga.tags.fetchAll(db)
        let origins: [OriginExtended] = try manga.originsExtended.fetchAll(db)
        
        // Use the chapters query interface request from the Manga model
        let chapters = try manga.chapters.fetchAll(db)
        
        return Detail(
            manga: manga,
            titles: titles,
            covers: covers,
            authors: authors,
            tags: tags,
            origins: origins,
            chapters: chapters
        )
    }
    
    private func insertRelatedEntities(
        for payload: DetailDTO,
        mangaId: Int64,
        sourceId: Int64,
        db: Database
    ) throws {
        // Insert titles
        try insertTitles(payload.manga.alternativeTitles, mangaId: mangaId, db: db)
        
        // Insert covers
        try insertCovers(payload.origin.covers, mangaId: mangaId, db: db)
        
        // Insert authors
        try insertAuthors(payload.manga.authors, mangaId: mangaId, db: db)
        
        // Insert tags
        try insertTags(payload.manga.tags, mangaId: mangaId, db: db)
        
        // Insert origin
        let origin = try insertOrigin(payload.origin, mangaId: mangaId, sourceId: sourceId, db: db)
        
        // Insert chapters
        if let originId = origin.id {
            try insertChapters(payload.chapters, originId: originId, db: db)
        }
    }
    
    private func insertTitles(_ titles: [String], mangaId: Int64, db: Database) throws {
        for title in titles {
            try Title(title: title, mangaId: mangaId).insert(db)
        }
    }
    
    private func insertCovers(_ coverUrls: [String], mangaId: Int64, db: Database) throws {
        for (index, coverUrl) in coverUrls.enumerated() {
            try Cover(
                active: index == 0, // First one is active
                url: coverUrl,
                path: coverUrl,
                mangaId: mangaId
            ).insert(db)
        }
    }
    
    private func insertAuthors(_ authorNames: [String], mangaId: Int64, db: Database) throws {
        for authorName in authorNames {
            let author = try Author.findOrCreate(db, instance: Author(name: authorName))
            if let authorId = author.id {
                try MangaAuthor(authorId: authorId, mangaId: mangaId).insert(db, onConflict: .ignore)
            }
        }
    }
    
    private func insertTags(_ tagNames: [String], mangaId: Int64, db: Database) throws {
        for tagName in tagNames {
            let tag = try Tag.findOrCreate(db, instance: Tag(name: tagName))
            if let tagId = tag.id {
                try MangaTag(tagId: tagId, mangaId: mangaId).insert(db)
            }
        }
    }
    
    private func insertOrigin(_ originPayload: OriginDTO, mangaId: Int64, sourceId: Int64, db: Database) throws -> Origin {
        return try Origin(
            mangaId: mangaId,
            sourceId: sourceId,
            slug: originPayload.slug,
            url: originPayload.url,
            referer: originPayload.referer,
            classification: Classification(rawValue: originPayload.classification) ?? .Unknown,
            status: PublishStatus(rawValue: originPayload.status) ?? .Unknown,
            createdAt: Date.javascriptDate(originPayload.creation)
        ).insertAndFetch(db)
    }
    
    private func insertChapters(_ chapterPayloads: [ChapterDTO], originId: Int64, db: Database) throws {
        for chapterPayload in chapterPayloads {
            let scanlator = try Scanlator.findOrCreate(
                db,
                instance: Scanlator(originId: originId, name: chapterPayload.scanlator)
            )
            
            if let scanlatorId = scanlator.id {
                try Chapter(
                    originId: originId,
                    scanlatorId: scanlatorId,
                    title: chapterPayload.title,
                    slug: chapterPayload.slug,
                    number: chapterPayload.number,
                    date: Date.javascriptDate(chapterPayload.date)
                ).insert(db)
            }
        }
    }
    
    private func fetchSimilarTaggedManga(db: Database, mangaId: Int64) throws -> [Entry] {
        return try Manga.entry
            .filter(Manga.Columns.inLibrary)
            .filter(Manga.Columns.id != mangaId)
            .filter(sql: """
            mangaId IN (
                SELECT DISTINCT mt2.mangaId 
                FROM mangaTag mt2 
                WHERE mt2.tagId IN (
                    SELECT mt1.tagId 
                    FROM mangaTag mt1 
                    WHERE mt1.mangaId = ?
                )
                AND mt2.mangaId != ?
            )
        """, arguments: [mangaId, mangaId])
            .limit(10)
            .fetchAll(db)
    }
    
    private func fetchSameCollectionManga(db: Database, mangaId: Int64) throws -> [Entry] {
        return try Manga.entry
            .filter(Manga.Columns.inLibrary)
            .filter(Manga.Columns.id != mangaId)
            .filter(sql: """
            mangaId IN (
                SELECT DISTINCT mc2.mangaId 
                FROM mangaCollection mc2 
                WHERE mc2.collectionId IN (
                    SELECT mc1.collectionId 
                    FROM mangaCollection mc1 
                    WHERE mc1.mangaId = ?
                )
                AND mc2.mangaId != ?
            )
        """, arguments: [mangaId, mangaId])
            .limit(10)
            .fetchAll(db)
    }
    
    private func fetchSameAuthorManga(db: Database, mangaId: Int64) throws -> [Entry] {
        return try Manga.entry
            .filter(Manga.Columns.inLibrary)
            .filter(Manga.Columns.id != mangaId)
            .filter(sql: """
            mangaId IN (
                SELECT DISTINCT ma2.mangaId 
                FROM mangaAuthor ma2 
                WHERE ma2.authorId IN (
                    SELECT ma1.authorId 
                    FROM mangaAuthor ma1 
                    WHERE ma1.mangaId = ?
                )
                AND ma2.mangaId != ?
            )
        """, arguments: [mangaId, mangaId])
            .limit(10)
            .fetchAll(db)
    }
    
    private func fetchSameScanlatorManga(db: Database, mangaId: Int64) throws -> [Entry] {
        return try Manga.entry
            .filter(Manga.Columns.inLibrary)
            .filter(Manga.Columns.id != mangaId)
            .filter(sql: """
            mangaId IN (
                SELECT DISTINCT o2.mangaId 
                FROM origin o2 
                JOIN chapter c2 ON c2.originId = o2.id 
                WHERE c2.scanlatorId IN (
                    SELECT DISTINCT c1.scanlatorId 
                    FROM chapter c1 
                    JOIN origin o1 ON c1.originId = o1.id 
                    WHERE o1.mangaId = ?
                )
                AND o2.mangaId != ?
            )
        """, arguments: [mangaId, mangaId])
            .limit(10)
            .fetchAll(db)
    }
}

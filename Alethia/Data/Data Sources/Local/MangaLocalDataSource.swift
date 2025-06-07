//
//  MangaLocalDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import Combine
import GRDB

final class MangaLocalDataSource {
    private let database: DatabaseWriter
    
    init(database: DatabaseWriter = DatabaseProvider.shared.writer) {
        self.database = database
    }
}

// MARK: - Public Methods

// MARK: Library Operations
extension MangaLocalDataSource {
    func getLibrary(filters: LibraryFilters, collection: Int64?) -> AnyPublisher<[Entry], Error> {
        let search = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ValueObservation
            .tracking { [weak self] db -> [Entry] in
                guard let self = self else { return [] }
                
                var request = Entry
                    .all()
                    .filter(Entry.Columns.inLibrary)
                
                // Apply collection filter
                request = try self.applyCollectionFilter(to: request, collection: collection, db: db)
                
                // Apply date filters
                request = filters.addedAt.apply(to: request, column: Entry.Columns.addedAt)
                request = filters.updatedAt.apply(to: request, column: Entry.Columns.updatedAt)
                
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
    
    func toggleMangaInLibrary(mangaId: Int64, newValue: Bool) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.inLibrary = newValue
            try manga.update(db)
        }
    }
    
    func addMangaToLibrary(mangaId: Int64, collections: [Int64]) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            for collectionId in collections {
                guard try Collection.fetchOne(db, key: collectionId) != nil else {
                    throw CollectionError.notFound(collectionId)
                }
                
                try MangaCollection(mangaId: mangaId, collectionId: collectionId)
                    .insert(db, onConflict: .ignore)
            }
            
            manga.inLibrary = true
            manga.addedAt = Date()
            try manga.update(db)
        }
    }
    
    func removeMangaFromLibrary(mangaId: Int64) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            // Remove from all collections first
            try MangaCollection
                .filter(MangaCollection.Columns.mangaId == mangaId)
                .deleteAll(db)
            
            // after successful collection removal set manga as not in library
            manga.inLibrary = false
            try manga.update(db)
        }
    }
    
    func updateMangaCollections(mangaId: Int64, collectionIds: [Int64]) throws {
        try database.write { db in
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            // Verify all collections exist
            for collectionId in collectionIds {
                guard try Collection.fetchOne(db, key: collectionId) != nil else {
                    throw CollectionError.notFound(collectionId)
                }
            }
            
            // Remove all existing collection associations
            try MangaCollection
                .filter(MangaCollection.Columns.mangaId == mangaId)
                .deleteAll(db)
            
            // Add new collection associations
            for collectionId in collectionIds {
                try MangaCollection(mangaId: mangaId, collectionId: collectionId)
                    .insert(db)
            }
            
            // Note: We DON'T update addedAt or inLibrary status here
            // The manga remains in library with its original added date
        }
    }
}

// MARK: Manga CRUD Operations
extension MangaLocalDataSource {
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
        }
        .publisher(in: database, scheduling: .immediate)
        .catch { _ in Just([]) }
        .eraseToAnyPublisher()
    }
    
    func addMangaOrigin(payload: DetailDTO, mangaId: Int64, sourceId: Int64?) throws {
        try self.database.write { db in
            guard let sourceId = sourceId else {
                throw SourceError.notFound
            }
            
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            try self.insertRelatedEntities(
                for: payload,
                mangaId: mangaId,
                sourceId: sourceId,
                db: db
            )
        }
    }
}

// MARK: Manga Metadata Operations
extension MangaLocalDataSource {
    func updateMangaOrientation(mangaId: Int64, newValue: Orientation) throws {
        try database.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.orientation = newValue
            try manga.update(db)
        }
    }
    
    func updateMangaCover(mangaId: Int64, coverId: Int64) throws {
        try database.write { db in
            // First, verify the manga exists
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            // Verify the cover exists and belongs to this manga
            guard let newActiveCover = try Cover.fetchOne(db, key: coverId),
                  newActiveCover.mangaId == mangaId else {
                throw MangaError.notFound
            }
            
            // Deactivate all covers for this manga
            try Cover
                .filter(Cover.Columns.mangaId == mangaId)
                .updateAll(db, Cover.Columns.active.set(to: false))
            
            // Activate the selected cover
            var updatedCover = newActiveCover
            updatedCover.active = true
            try updatedCover.update(db)
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

// MARK: Recommendation Operations
extension MangaLocalDataSource {
    func getMangaRecommendations(mangaId: Int64) throws -> RecommendedEntries {
        return try database.read { db in
            // Get the target manga to ensure it exists
            guard try Manga.fetchOne(db, key: mangaId) != nil else {
                throw MangaError.notFound
            }
            
            //            // 1. Similar tags - manga that share tags with the target manga
            //            let withSimilarTags = try fetchSimilarTaggedManga(db: db, mangaId: mangaId)
            //
            //            // 2. Same collection - manga in the same collections
            //            let fromSameCollection = try fetchSameCollectionManga(db: db, mangaId: mangaId)
            //
            //            // 3. Same author - other works by the same authors
            //            let otherWorksByAuthor = try fetchSameAuthorManga(db: db, mangaId: mangaId)
            //
            //            // 4. Same scanlator - other series by the same scanlators
            //            let otherSeriesByScanlator = try fetchSameScanlatorManga(db: db, mangaId: mangaId)
            
            return RecommendedEntries(
                withSimilarTags: [],
                fromSameCollection: [],
                otherWorksByAuthor: [],
                otherSeriesByScanlator: []
            )
        }
    }
}

// MARK: - Private Methods

// MARK: Library Filtering Helpers
private extension MangaLocalDataSource {
    func applyCollectionFilter(
        to request: QueryInterfaceRequest<Entry>,
        collection: Int64?,
        db: Database
    ) throws -> QueryInterfaceRequest<Entry> {
        // if collectionId is nil just return since we assume its 'default'.
        // there is technically no way for a non nil collection id to be passed in.
        guard let collectionId = collection else { return request }
        
        // Validate collection exists
        guard try Collection.fetchOne(db, key: collectionId) != nil else {
            throw CollectionError.notFound(collectionId)
        }
        
        return request.filter(sql: """
        mangaId IN (
            SELECT mc.mangaId 
            FROM mangaCollection mc 
            WHERE mc.collectionId = ?
        )
    """, arguments: [collectionId])
    }
    
    func applyPublishStatusFilter(
        to request: QueryInterfaceRequest<Entry>,
        statuses: [PublishStatus]
    ) -> QueryInterfaceRequest<Entry> {
        guard !statuses.isEmpty else { return request }
        
        let statusValues = statuses.map { $0.rawValue }
        
        let sql: SQL = """
        mangaId IN (
            SELECT DISTINCT o.mangaId
            FROM origin o
            WHERE o.status IN \(statusValues)
            AND o.priority = (
                SELECT MIN(o2.priority)
                FROM origin o2
                WHERE o2.mangaId = o.mangaId
            )
        )
        """
        
        return request.filter(sql)
    }
    
    func applyClassificationFilter(
        to request: QueryInterfaceRequest<Entry>,
        classifications: [Classification]
    ) -> QueryInterfaceRequest<Entry> {
        guard !classifications.isEmpty else { return request }
        
        let classificationValues = classifications.map { $0.rawValue }
        
        let sql: SQL = """
        mangaId IN (
            SELECT DISTINCT o.mangaId
            FROM origin o
            WHERE o.classification IN \(classificationValues)
            AND o.priority = (
                SELECT MIN(o2.priority)
                FROM origin o2
                WHERE o2.mangaId = o.mangaId
            )
        )
        """
        
        return request.filter(sql)
    }
    
    func applySearchFilter(
        to request: QueryInterfaceRequest<Entry>,
        search: String
    ) -> QueryInterfaceRequest<Entry> {
        return request.filter(
            sql: """
            (INSTR(LOWER(title), LOWER(?)) > 0 OR 
             EXISTS(
                SELECT 1 FROM title t 
                WHERE t.mangaId = entry.mangaId 
                AND INSTR(LOWER(t.title), LOWER(?)) > 0
             ))
            """,
            arguments: [search, search]
        )
    }
    
    func applySorting(
        to request: QueryInterfaceRequest<Entry>,
        type: LibrarySortType,
        direction: LibrarySortDirection
    ) -> QueryInterfaceRequest<Entry> {
        
        let isAscending = direction == .ascending
        
        switch type {
        case .title:
            // change order for title since usually descending is a-z
            return request.order(isAscending ? Entry.Columns.title.desc : Entry.Columns.title.asc)
            
        case .added:
            // Sort by when manga was added to library
            return request.order(isAscending ? Entry.Columns.addedAt.asc : Entry.Columns.addedAt.desc)
            
        case .updated:
            // Sort by when manga was last updated (new chapters)
            return request.order(isAscending ? Entry.Columns.updatedAt.asc : Entry.Columns.updatedAt.desc)
            
        case .read:
            // Sort by when manga was last read
            return request.order(isAscending ? Entry.Columns.lastReadAt.asc : Entry.Columns.lastReadAt.desc)
        }
    }
}

// MARK: Data Fetching Helpers
private extension MangaLocalDataSource {
    func findMangasByTitle(db: Database, title: String) throws -> [Manga] {
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
    
    func fetchDetailWithChapters(db: Database, manga: Manga) throws -> Detail? {
        let titles: [Title] = try manga.titles.order(Title.Columns.title).fetchAll(db)
        let covers: [Cover] = try manga.covers.fetchAll(db)
        let authors: [Author] = try manga.authors.fetchAll(db)
        let tags: [Tag] = try manga.tags.fetchAll(db)
        let origins: [OriginExtended] = try manga.originsExtended.fetchAll(db)
        
        // Use the chapters query interface request from the Manga model
        let chapters = try manga.chapters.fetchAll(db)
        
        let collections = try manga.collectionsExtended.fetchAll(db)
        
        return Detail(
            manga: manga,
            titles: titles,
            covers: covers,
            authors: authors,
            tags: tags,
            origins: origins,
            chapters: chapters,
            collections: collections
        )
    }
}

// MARK: Data Update Helpers
private extension MangaLocalDataSource {
    func updateMangaUpdatedAt(mangaId: Int64, db: Database) throws {
        // Get the most recent chapter date across all origins for this manga
        let sql = """
        SELECT MAX(c.date) as latestDate
        FROM chapter c
        JOIN origin o ON c.originId = o.id
        WHERE o.mangaId = ?
        """
        
        let latestChapterDate = try Date.fetchOne(db, sql: sql, arguments: [mangaId])
        
        // Only update if we found a date
        if let date = latestChapterDate {
            guard var manga = try Manga.fetchOne(db, key: mangaId) else {
                throw MangaError.notFound
            }
            
            manga.updatedAt = date
            try manga.update(db)
        }
    }
}

// MARK: Data Insertion Helpers
private extension MangaLocalDataSource {
    func insertRelatedEntities(
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
        
        // Update manga updated at prop
        try updateMangaUpdatedAt(mangaId: mangaId, db: db)
    }
    
    func insertTitles(_ titles: [String], mangaId: Int64, db: Database) throws {
        for title in titles {
            // if title already exists in manga-title kvp it will just silently fail
            try Title(title: title, mangaId: mangaId).insert(db)
        }
    }
    
    func insertCovers(_ coverUrls: [String], mangaId: Int64, db: Database) throws {
        guard !coverUrls.isEmpty else { return }
        
        // Check if manga already has covers
        let existingCoversCount = try Cover
            .filter(Cover.Columns.mangaId == mangaId)
            .fetchCount(db)
        
        let hasExistingCovers = existingCoversCount > 0
        
        for (index, coverUrl) in coverUrls.enumerated() {
            // Only set the first cover as active if there are no existing covers
            let shouldBeActive = !hasExistingCovers && index == 0
            
            try Cover(
                active: shouldBeActive,
                url: coverUrl,
                path: coverUrl,
                mangaId: mangaId
            ).insert(db)
        }
    }
    
    func insertAuthors(_ authorNames: [String], mangaId: Int64, db: Database) throws {
        for authorName in authorNames {
            let author = try Author.findOrCreate(db, instance: Author(name: authorName))
            if let authorId = author.id {
                try MangaAuthor(authorId: authorId, mangaId: mangaId).insert(db, onConflict: .ignore)
            }
        }
    }
    
    func insertTags(_ tagNames: [String], mangaId: Int64, db: Database) throws {
        for tagName in tagNames {
            let tag = try Tag.findOrCreate(db, instance: Tag(name: tagName))
            if let tagId = tag.id {
                try MangaTag(tagId: tagId, mangaId: mangaId).insert(db)
            }
        }
    }
    
    /// Origin insertion fn needs to manage origin priority
    func insertOrigin(_ originPayload: OriginDTO, mangaId: Int64, sourceId: Int64, db: Database) throws -> Origin {
        // Get existing origins for this manga to determine next priority
        let existingOrigins = try Origin
            .filter(Origin.Columns.mangaId == mangaId)
            .order(Origin.Columns.priority.asc)
            .fetchAll(db)
        
        // Determine the next available priority
        let nextPriority = (existingOrigins.last?.priority ?? -1) + 1
        
        return try Origin(
            mangaId: mangaId,
            sourceId: sourceId,
            slug: originPayload.slug,
            url: originPayload.url,
            referer: originPayload.referer,
            classification: Classification(rawValue: originPayload.classification) ?? .Unknown,
            status: PublishStatus(rawValue: originPayload.status) ?? .Unknown,
            createdAt: Date.javascriptDate(originPayload.creation),
            priority: nextPriority
        ).insertAndFetch(db)
    }
    
    /// Chapter insertion fn need to manage scanlator priority
    func insertChapters(_ chapterPayloads: [ChapterDTO], originId: Int64, db: Database) throws {
        // Group chapters by scanlator to process them efficiently
        let chaptersByScanlator = Dictionary(grouping: chapterPayloads) { $0.scanlator }
        
        // Get existing scanlators for this origin to determine next priority
        let existingScanlators = try Scanlator
            .filter(Scanlator.Columns.originId == originId)
            .order(Scanlator.Columns.priority.asc)
            .fetchAll(db)
        
        // Track the highest priority so far
        var nextPriority = existingScanlators.last?.priority ?? -1 // -1 so if none found it increments to 0 (highest priority)
        
        // Process each scanlator group
        for (scanlatorName, chapters) in chaptersByScanlator {
            // Try to find existing scanlator for this origin
            let existingScanlator = existingScanlators.first { $0.name == scanlatorName }
            
            let scanlator: Scanlator
            if let existing = existingScanlator {
                // Use existing scanlator
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
            }
            
            // Insert all chapters for this scanlator
            if let scanlatorId = scanlator.id {
                for chapterPayload in chapters {
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
    }
}

// MARK: Recommendation Query Helpers
private extension MangaLocalDataSource {
    @available(*, deprecated, message: "Refactor Out")
    func fetchSimilarTaggedManga(db: Database, mangaId: Int64) throws -> [Entry] {
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
    
    @available(*, deprecated, message: "Refactor Out")
    func fetchSameCollectionManga(db: Database, mangaId: Int64) throws -> [Entry] {
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
    
    @available(*, deprecated, message: "Refactor Out")
    func fetchSameAuthorManga(db: Database, mangaId: Int64) throws -> [Entry] {
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
    
    @available(*, deprecated, message: "Refactor Out")
    func fetchSameScanlatorManga(db: Database, mangaId: Int64) throws -> [Entry] {
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

// MARK: - LibraryDate Extension
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

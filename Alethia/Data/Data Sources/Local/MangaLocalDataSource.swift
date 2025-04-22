import Foundation
import Combine
import GRDB

final class MangaLocalDataSource {
    func getLibrary() -> AnyPublisher<[Entry], Error> {
        return ValueObservation
            .tracking { db -> [Entry] in
                let sql = """
                    SELECT e.*
                    FROM entry e
                    JOIN Manga m ON e.mangaId = m.id
                    WHERE m.inLibrary = 1
                """
                
                let entries = try Entry.fetchAll(db, sql: sql)
                
                let items: [Entry] = try entries.map { entry in
                    guard let mangaId = entry.mangaId,
                          let sourceId = entry.sourceId,
                          let source = try Source.fetchOne(db, key: sourceId),
                          let host = try Host.fetchOne(db, key: source.hostId)
                    else { throw ApplicationError.internalError }
                    
                    guard let origin = try Origin
                        .filter(Origin.Columns.mangaId == mangaId)
                        .order(Origin.Columns.priority.asc)
                        .fetchOne(db)
                    else {
                        throw ApplicationError.internalError
                    }
                    
                    // cover can be nil if none were set
                    let cover = try Cover
                        .filter(Cover.Columns.mangaId == mangaId && Cover.Columns.active)
                        .fetchOne(db)
                    
                    var contextful = entry
                    
                    contextful.fetchUrl = URL.appendingPaths(host.baseUrl, source.path, "manga", origin.slug)!.absoluteString
                    contextful.cover = cover?.url ?? nil
                    
                    return contextful
                }
                
                return items
            }
            .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
            .eraseToAnyPublisher()
    }
    
    func saveNewManga(payload: DetailDTO, with sourceId: Int64?) -> AnyPublisher<Detail, Error> {
        return Deferred {
            Future<Detail, Error> { promise in
                do {
                    try DatabaseProvider.shared.writer.write { db in
                        // --- verify corresponding source exists ---
                        let source = try Source.filter(id: sourceId).fetchOne(db)
                        guard let sourceId = source?.id else {
                            throw SourceError.notFound
                        }
                        
                        // --- Insert manga and get the inserted ID ---
                        var manga = Manga(title: payload.manga.title, synopsis: payload.manga.synopsis)
                        manga = try manga.insertAndFetch(db)
                        guard let mangaId = manga.id else {
                            throw MangaError.notFound
                        }
                        
                        // --- perform insert on related props ---
                        try self.insertRelatedEntities(
                            for: payload,
                            mangaId: mangaId,
                            sourceId: sourceId,
                            db: db
                        )
                        
                        // --- return the detail object with unified chapter list ---
                        let detail = try self.fetchDetailWithChapters(db: db, manga: manga)
                        
                        guard let detail = detail else {
                            throw MangaError.notFound
                        }
                        
                        promise(.success(detail))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getMangaDetail(entry: Entry) -> AnyPublisher<[Detail], Never> {
        let mangaId = entry.mangaId
        let title = entry.title
        
        return ValueObservation
            .tracking { db -> [Detail] in
                var details: [Detail] = []
                
                // First: fetch by ID (if valid)
                if let manga = try Manga.fetchOne(db, key: mangaId),
                   let detail = try self.fetchDetailWithChapters(db: db, manga: manga) {
                    details.append(detail)
                }
                
                // Then: fetch by title, across both Manga.title and Title.title
                let mangas = try Manga
                    .filter(Manga.Columns.title == title || Title.Columns.title == title)
                    .joining(optional: Manga.titles.filter(Title.Columns.title == title))
                    .distinct()
                    .order(
                        sql: """
                        CASE
                            WHEN manga.title = ? THEN 0
                            ELSE 1
                        END
                        """,
                        arguments: [title]
                    )
                    .fetchAll(db)
                
                for manga in mangas where !details.contains(where: { $0.manga.id == manga.id }) {
                    if let detail = try self.fetchDetailWithChapters(db: db, manga: manga) {
                        details.append(detail)
                    }
                }
                
                return details
            }
            .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
    }
    
    func toggleMangaInLibrary(mangaId: Int64, newValue: Bool) throws -> Void {
        try DatabaseProvider.shared.writer.write { db in
            guard var manga = try Manga.fetchOne(db, key: mangaId) else { throw MangaError.notFound }
            
            manga.inLibrary = newValue
            
            try manga.update(db)
        }
    }
}

private extension MangaLocalDataSource {
    // Post fetch retrieve
    private func fetchDetailWithChapters(db: Database, manga: Manga) throws -> Detail? {
        let titles = try manga.titles.fetchAll(db)
        let covers = try manga.covers.fetchAll(db)
        let authors = try manga.authors.fetchAll(db)
        let tags = try manga.tags.fetchAll(db)
        let origins = try manga.origins.fetchAll(db)
            .sorted { $0.priority < $1.priority }
        
        // Get prioritized chapters based on manga preferences
        let rawChapters = try self.getPrioritizedChapters(
            db: db,
            manga: manga,
            origins: origins
        )
        
        let chapters = try rawChapters.map { chapter in
            guard let origin = try Origin.filter(id: chapter.originId).fetchOne(db),
                  let scanlator = try Scanlator.filter(id: chapter.scanlatorId).fetchOne(db)
            else { throw ApplicationError.internalError }
            
            // source can be nil hence not inside guard clause
            let source = try Source.filter(id: origin.sourceId).fetchOne(db)
            
            return ChapterExtended(
                chapter: chapter,
                scanlator: scanlator,
                origin: origin,
                source: source
            )
        }
        
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
    
    private func getPrioritizedChapters(db: Database, manga: Manga, origins: [Origin]) throws -> [Chapter] {
        if origins.isEmpty {
            return []
        }
        
        // Determine which origins to use based on showAllChapters flag
        let relevantOriginIds = manga.showAllChapters
        ? origins.map { $0.id! }
        : [origins.first!.id!]
        
        // Build chapter query with origin filter
        var chapterQuery = Chapter.filter(relevantOriginIds.contains(Chapter.Columns.originId))
        
        // Filter half chapters if not showing them
        if !manga.showHalfChapters {
            chapterQuery = chapterQuery.filter(key: Double(Chapter.Columns.number.name)?.truncatingRemainder(dividingBy: 1) == 0)
        }
        
        // Get all chapters that match our criteria
        let allChapters = try chapterQuery.fetchAll(db)
        
        // Group chapters by number for prioritization
        let chaptersByNumber = Dictionary(grouping: allChapters) { $0.number }
        
        // Dictionary to map originId to priority for faster lookups
        let originPriorities = Dictionary(uniqueKeysWithValues: origins.map { ($0.id!, $0.priority) })
        
        // Create a lookup for scanlator priorities
        var scanlatorPriorities: [Int64: Int] = [:]
        for originId in relevantOriginIds {
            let scanlators = try Scanlator.filter(Scanlator.Columns.originId == originId).fetchAll(db)
            for scanlator in scanlators {
                if let id = scanlator.id {
                    scanlatorPriorities[id] = scanlator.priority
                }
            }
        }
        
        // Select the highest priority chapter for each chapter number
        var prioritizedChapters: [Chapter] = []
        
        for (_, chaptersWithSameNumber) in chaptersByNumber {
            // First prioritize by origin (lower priority value = higher priority)
            let sortedByOrigin = chaptersWithSameNumber.sorted {
                let priority1 = originPriorities[$0.originId] ?? Int.max
                let priority2 = originPriorities[$1.originId] ?? Int.max
                return priority1 < priority2
            }
            
            // Group the chapters by origin to handle scanlator priorities
            let chaptersByOrigin = Dictionary(grouping: sortedByOrigin) { $0.originId }
            
            // Get chapters from highest priority origin
            if let highestPriorityOriginId = chaptersByOrigin.keys.min(by: {
                (originPriorities[$0] ?? Int.max) < (originPriorities[$1] ?? Int.max)
            }), let chaptersFromOrigin = chaptersByOrigin[highestPriorityOriginId] {
                
                // If there's more than one chapter from the same origin (different scanlators),
                // prioritize by scanlator priority
                if chaptersFromOrigin.count > 1 {
                    let highestPriorityChapter = chaptersFromOrigin.min {
                        (scanlatorPriorities[$0.scanlatorId] ?? Int.max) < (scanlatorPriorities[$1.scanlatorId] ?? Int.max)
                    }
                    if let chapter = highestPriorityChapter {
                        prioritizedChapters.append(chapter)
                    }
                } else if let singleChapter = chaptersFromOrigin.first {
                    // Only one chapter from this origin, add it
                    prioritizedChapters.append(singleChapter)
                }
            }
        }
        
        // Sort chapters by number before returning
        return prioritizedChapters.sorted { $0.number > $1.number }
    }
    
    func insertRelatedEntities(
        for payload: DetailDTO,
        mangaId: Int64,
        sourceId: Int64,
        db: Database
    ) throws {
        // Insert alternative titles
        for title in payload.manga.alternativeTitles {
            try Title(title: title, mangaId: mangaId).insert(db)
        }
        
        // Insert covers
        for (index, coverUrl) in payload.origin.covers.enumerated() {
            try Cover(
                active: index == 0, // First one is active, rest are false
                url: coverUrl,
                path: coverUrl,
                mangaId: mangaId
            ).insert(db)
        }
        
        // Insert authors and relationships
        for authorName in payload.manga.authors {
            let author = try Author.findOrCreate(db, instance: Author(name: authorName))
            if let authorId = author.id {
                // Ignore as mapping already exists (case where Author name shows up twice as both author/artist))
                try MangaAuthor(authorId: authorId, mangaId: mangaId).insert(db, onConflict: .ignore)
            }
        }
        
        // Insert tags and relationships
        for tagName in payload.manga.tags {
            let tag = try Tag.findOrCreate(db, instance: Tag(name: tagName))
            if let tagId = tag.id {
                try MangaTag(tagId: tagId, mangaId: mangaId).insert(db)
            }
        }
        
        // Insert origin
        let origin = try Origin(
            mangaId: mangaId,
            sourceId: sourceId,
            slug: payload.origin.slug,
            url: payload.origin.url,
            referer: payload.origin.referer,
            classification: Classification(rawValue: payload.origin.classification) ?? .Unknown,
            status: PublishStatus(rawValue: payload.origin.status) ?? .Unknown
        ).insertAndFetch(db)
        
        // Insert chapters
        if let originId = origin.id {
            for chapter in payload.chapters {
                let scanlator = try Scanlator.findOrCreate(
                    db,
                    instance: Scanlator(originId: originId, name: chapter.scanlator)
                )
                
                if let scanlatorId = scanlator.id {
                    try Chapter(
                        originId: originId,
                        scanlatorId: scanlatorId,
                        title: chapter.title,
                        slug: chapter.slug,
                        number: chapter.number,
                        date: Date.javascriptDate(chapter.date)
                    ).insert(db)
                }
            }
        }
    }
}

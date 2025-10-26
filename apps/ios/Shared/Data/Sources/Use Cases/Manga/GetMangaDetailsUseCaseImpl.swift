//
//  GetMangaDetailsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import Domain
import GRDB

public final class GetMangaDetailsUseCaseImpl: GetMangaDetailsUseCase {
    private let repository: MangaRepository
    private let database: DatabaseConfiguration
    
    public init(repository: MangaRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(entry: Entry) -> AsyncStream<Result<[Manga], any Error>> {
        AsyncStream { continuation in
            // validate entry has required fields
            guard !entry.slug.isEmpty else {
                continuation.yield(.failure(BusinessError.invalidInput(reason: "Entry slug is empty")))
                continuation.finish()
                return
            }
            
            guard !entry.title.isEmpty else {
                continuation.yield(.failure(BusinessError.invalidInput(reason: "Entry title is empty")))
                continuation.finish()
                return
            }
            
            // create observation for manga data changes
            let observation = ValueObservation.tracking { [weak self] db -> [MangaBundle] in
                guard let self else { return [] }
                
                do {
                    // determine which manga to fetch based on entry
                    let mangaIds = try self.findMangaIds(for: entry, in: db)
                    guard !mangaIds.isEmpty else { return [] }
                    
                    // fetch complete manga data for each id
                    return try mangaIds.compactMap { mangaId in
                        try self.fetchMangaBundle(mangaId: mangaId, in: db)
                    }
                } catch {
                    throw error
                }
            }
            
            var hasFetchedRemote = false
            
            let task = Task { [weak self] in
                guard let self else { return }
                
                do {
                    for try await mangaBundles in observation.values(in: self.database.reader) {
                        if Task.isCancelled { break }
                        
                        if !mangaBundles.isEmpty {
                            // map bundles to domain entities
                            let result = self.mapBundlesToResult(mangaBundles)
                            continuation.yield(result)
                        } else if !hasFetchedRemote && entry.sourceId != nil {
                            // no local data found, fetch from remote if we have source id
                            hasFetchedRemote = true
                            
                            Task { [weak self] in
                                await self?.fetchAndSaveFromRemote(entry: entry, continuation: continuation)
                            }
                        } else if entry.sourceId == nil {
                            // no source id means we can't fetch remotely
                            continuation.yield(.failure(BusinessError.resourceNotFound(
                                type: "Manga",
                                identifier: entry.slug
                            )))
                            continuation.finish()
                            break
                        }
                    }
                } catch {
                    continuation.yield(.failure(self.mapError(error)))
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Private Database Operations
    
    private func findMangaIds(for entry: Entry, in db: Database) throws -> [Int64] {
        // if entry already has manga id, use it directly
        if let mangaId = entry.mangaId {
            return [mangaId]
        }
        
        // search by slug first (highest priority)
        var mangaIds = try repository.search(bySlug: entry.slug, sourceId: entry.sourceId, in: db)
        
        // if no slug matches, search by title
        if mangaIds.isEmpty {
            mangaIds = try repository.search(byTitle: entry.title, in: db)
        }
        
        return mangaIds
    }
    
    private func fetchMangaBundle(mangaId: Int64, in db: Database) throws -> MangaBundle? {
        // fetch manga record
        guard let manga = try repository.fetch(mangaId: mangaId, in: db) else {
            return nil
        }
        
        // fetch all related data
        let authors = try repository.fetchAuthors(mangaId: mangaId, in: db)
        let tags = try repository.fetchTags(mangaId: mangaId, in: db)
        let covers = try repository.fetchCovers(mangaId: mangaId, in: db)
        let alternativeTitles = try repository.fetchAlternativeTitles(mangaId: mangaId, in: db)
        let origins = try repository.fetchOrigins(mangaId: mangaId, in: db)
        let chapters = try repository.fetchChaptersWithMetadata(mangaId: mangaId, in: db)
        let collections = try repository.fetchCollections(mangaId: mangaId, in: db)
        
        // fetch sources for each origin
        var sources: [Int64: (source: Any, host: Any)] = [:]
        for origin in origins {
            if let originRecord = origin as? OriginRecord,
               let originId = originRecord.id?.rawValue,
               let sourceId = originRecord.sourceId?.rawValue,
               let sourceData = try repository.fetch(sourceId: sourceId, in: db) {
                sources[originId] = sourceData
            }
        }
        
        return MangaBundle(
            manga: manga,
            authors: authors,
            tags: tags,
            covers: covers,
            alternativeTitles: alternativeTitles,
            origins: origins,
            sources: sources,
            chapters: chapters,
            collections: collections
        )
    }
    
    // MARK: - Remote Fetching
    
    private func fetchAndSaveFromRemote(
        entry: Entry,
        continuation: AsyncStream<Result<[Manga], Error>>.Continuation
    ) async {
        do {
            guard let sourceId = entry.sourceId else {
                throw BusinessError.invalidInput(reason: "Source ID required for remote fetch")
            }
            
            // fetch source and host data inside the database transaction
            let repository = self.repository
            let sourceData = try await database.reader.read { db -> (sourceSlug: String, hostURL: URL)? in
                guard let (source, host) = try repository.fetch(sourceId: sourceId, in: db) else {
                    return nil
                }
                
                guard let sourceRecord = source as? SourceRecord,
                      let hostRecord = host as? HostRecord else {
                    return nil
                }
                
                return (sourceSlug: sourceRecord.slug, hostURL: hostRecord.url)
            }
            
            guard let (sourceSlug, hostURL) = sourceData else {
                throw BusinessError.resourceNotFound(type: "Source", identifier: String(sourceId))
            }
            
            // fetch manga and chapters from remote
            let mangaDTO = try await repository.remoteFetchManga(
                sourceSlug: sourceSlug,
                entrySlug: entry.slug,
                hostURL: hostURL
            )
            
            let chaptersDTO = try await repository.remoteFetchChapters(
                sourceSlug: sourceSlug,
                entrySlug: entry.slug,
                hostURL: hostURL
            )
            
            // save to database
            try await database.writer.write { db in
                // find or create manga
                let manga = try repository.findOrCreate(
                    title: mangaDTO.title,
                    synopsis: mangaDTO.synopsis,
                    in: db
                )
                
                guard let mangaRecord = manga as? MangaRecord,
                      let mangaId = mangaRecord.id else {
                    throw SystemError.mappingFailed(reason: "Failed to get manga ID after save")
                }
                
                // update manga metadata
                try repository.update(
                    mangaId: mangaId.rawValue,
                    updatedAt: mangaDTO.updatedAt,
                    lastFetchedAt: Date(),
                    in: db
                )
                
                // save all related data
                try repository.saveAuthors(
                    mangaId: mangaId.rawValue,
                    names: mangaDTO.authors,
                    in: db
                )
                
                try repository.saveTags(
                    mangaId: mangaId.rawValue,
                    names: mangaDTO.tags,
                    in: db
                )
                
                // save covers
                let primaryCoverString = entry.cover.absoluteString

                // to determine a primary cover from the entry cover - extract base identifier (everything before first dot in last path component)
                func extractBaseIdentifier(from urlString: String) -> String? {
                    guard let url = URL(string: urlString),
                          let dotIndex = url.lastPathComponent.firstIndex(of: ".") else {
                        return URL(string: urlString)?.lastPathComponent
                    }
                    return String(url.lastPathComponent[..<dotIndex])
                }

                // try exact match first
                var primaryIndex = mangaDTO.covers.firstIndex(where: { $0 == primaryCoverString })

                // if no exact match, try fuzzy match using base identifiers
                if primaryIndex == nil, let entryBase = extractBaseIdentifier(from: primaryCoverString) {
                    primaryIndex = mangaDTO.covers.firstIndex { coverURL in
                        let dtoBase = extractBaseIdentifier(from: coverURL)
                        return dtoBase == entryBase
                    }
                }

                let coverDataList = mangaDTO.covers.enumerated().compactMap { index, urlString -> CoverData? in
                    guard let coverURL = URL(string: urlString) else {
                        return nil
                    }
                    
                    // set as primary if matches entry cover, otherwise use first cover as fallback
                    let isPrimary = primaryIndex == index || (primaryIndex == nil && index == 0)
                    
                    return CoverData(
                        mangaId: mangaId.rawValue,
                        isPrimary: isPrimary,
                        localPath: coverURL,
                        remotePath: coverURL
                    )
                }
                
                try repository.replaceCovers(
                    mangaId: mangaId.rawValue,
                    covers: coverDataList,
                    in: db
                )
                
                // save alternative titles
                try repository.replaceAlternativeTitles(
                    mangaId: mangaId.rawValue,
                    titles: mangaDTO.alternativeTitles,
                    in: db
                )
                
                // save origin
                let originData = OriginData(
                    mangaId: mangaId.rawValue,
                    sourceId: sourceId,
                    slug: mangaDTO.slug,
                    url: URL(string: mangaDTO.url)!,
                    priority: 0,
                    classification: Classification(rawValue: mangaDTO.classification) ?? .Unknown,
                    status: Status(rawValue: mangaDTO.publication) ?? .Unknown
                )
                let origin = try repository.save(origin: originData, in: db)
                
                // save chapters with scanlators
                if let originRecord = origin as? OriginRecord,
                   let originId = originRecord.id {
                    // group chapters by scanlator
                    let chaptersByScanlator = Dictionary(grouping: chaptersDTO) { $0.scanlator }
                    
                    for (scanlatorName, chapterGroup) in chaptersByScanlator {
                        // save scanlator
                        let scanlator = try repository.save(scanlatorName: scanlatorName, in: db)
                        
                        guard let scanlatorRecord = scanlator as? ScanlatorRecord,
                              let scanlatorId = scanlatorRecord.id else { continue }
                        
                        // save scanlator priority
                        let maxPriority = try repository.fetchMaxPriority(originId: originId.rawValue, in: db) ?? -1
                        let priorityData = ScanlatorPriorityData(
                            originId: originId.rawValue,
                            scanlatorId: scanlatorId.rawValue,
                            priority: maxPriority + 1
                        )
                        try repository.save(priority: priorityData, in: db)
                        
                        // save chapters
                        let chapterDataList = chapterGroup.map { chapterDTO in
                            ChapterData(
                                originId: originId.rawValue,
                                scanlatorId: scanlatorId.rawValue,
                                slug: chapterDTO.slug,
                                title: chapterDTO.title,
                                number: chapterDTO.number,
                                date: chapterDTO.date,
                                url: URL(string: chapterDTO.url)!,
                                language: LanguageCode(chapterDTO.language)
                            )
                        }
                        try repository.saveChapters(chapterDataList, in: db)
                    }
                }
            }
            
        } catch {
            continuation.yield(.failure(self.mapError(error)))
        }
    }
    
    // MARK: - Mapping
    
    private func mapBundlesToResult(_ bundles: [MangaBundle]) -> Result<[Manga], Error> {
        do {
            let mangaEntities = try bundles.map { bundle in
                try mapBundleToEntity(bundle)
            }
            return .success(mangaEntities)
        } catch {
            return .failure(error)
        }
    }
    
    private func mapBundleToEntity(_ bundle: MangaBundle) throws -> Manga {
        // cast manga record
        guard let mangaRecord = bundle.manga as? MangaRecord else {
            throw SystemError.mappingFailed(reason: "Invalid manga record type")
        }
        
        guard let mangaId = mangaRecord.id else {
            throw SystemError.mappingFailed(reason: "Manga ID is nil")
        }
        
        // map all the data to domain entities
        let authorNames = (bundle.authors as? [AuthorRecord] ?? []).map(\.name)
        let tagNames = (bundle.tags as? [TagRecord] ?? []).filter(\.isCanonical).map(\.displayName)
        
        // sort covers with primary first
        let covers = (bundle.covers as? [CoverRecord] ?? [])
            .sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary { return lhs.isPrimary }
                return (lhs.id?.rawValue ?? 0) < (rhs.id?.rawValue ?? 0)
            }
            .map(\.remotePath)
        
        let altTitles = (bundle.alternativeTitles as? [AlternativeTitleRecord] ?? []).map(\.title)
        
        // map origins
        let origins = try (bundle.origins as? [OriginRecord] ?? []).map { origin in
            try mapOriginToEntity(origin, sources: bundle.sources)
        }
        
        // map chapters - use compactMap without throws since mapChapterToEntity returns optional
        let chapters = bundle.chapters.compactMap { chapterWithMetadata in
            mapChapterToEntity(chapterWithMetadata)
        }
        
        // map collections
        let collections = try bundle.collections.map { tuple in
            try mapCollectionToEntity(tuple)
        }
        
        // parse synopsis as markdown
        let attributedSynopsis = try AttributedString(
            markdown: mangaRecord.synopsis,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        )
        
        return Manga(
            id: mangaId.rawValue,
            title: mangaRecord.title,
            authors: authorNames,
            synopsis: attributedSynopsis,
            alternativeTitles: altTitles,
            tags: tagNames,
            covers: covers,
            origins: origins,
            chapters: chapters,
            collections: collections,
            inLibrary: mangaRecord.inLibrary,
            addedAt: mangaRecord.addedAt,
            updatedAt: mangaRecord.updatedAt,
            lastFetchedAt: mangaRecord.lastFetchedAt,
            lastReadAt: mangaRecord.lastReadAt,
            orientation: mangaRecord.orientation,
            showAllChapters: mangaRecord.showAllChapters,
            showHalfChapters: mangaRecord.showHalfChapters
        )
    }
    
    private func mapOriginToEntity(_ origin: OriginRecord, sources: [Int64: (source: Any, host: Any)]) throws -> Origin {
        guard let originId = origin.id else {
            throw SystemError.mappingFailed(reason: "Origin ID is nil")
        }
        
        // map source if available
        var domainSource: Source? = nil
        if let sourceData = sources[originId.rawValue],
           let sourceRecord = sourceData.source as? SourceRecord,
           let hostRecord = sourceData.host as? HostRecord {
            domainSource = try mapSourceToDomain(sourceRecord, host: hostRecord)
        }
        
        return Origin(
            id: originId.rawValue,
            slug: origin.slug,
            url: URL(string: origin.url)!,
            priority: origin.priority,
            classification: origin.classification,
            status: origin.status,
            source: domainSource
        )
    }
    
    private func mapChapterToEntity(_ chapterWithMetadata: ChapterWithMetadata) -> Chapter? {
        guard let chapterRecord = chapterWithMetadata.chapter as? ChapterRecord,
              let chapterId = chapterRecord.id else {
            return nil
        }
        
        return Chapter(
            id: chapterId.rawValue,
            slug: chapterRecord.slug,
            title: chapterRecord.title,
            number: chapterRecord.number,
            date: chapterRecord.date,
            scanlator: chapterWithMetadata.scanlatorName,
            language: chapterRecord.language,
            url: chapterRecord.url.absoluteString,
            icon: chapterWithMetadata.sourceIcon,
            progress: chapterRecord.progress
        )
    }
    
    private func mapCollectionToEntity(_ tuple: (collection: Any, count: Int)) throws -> Collection {
        guard let collectionRecord = tuple.collection as? CollectionRecord,
              let collectionId = collectionRecord.id else {
            throw SystemError.mappingFailed(reason: "Invalid collection record")
        }
        
        return Collection(
            id: collectionId.rawValue,
            name: collectionRecord.name,
            description: collectionRecord.description ?? "",
            count: tuple.count,
            createdAt: collectionRecord.createdAt,
            updatedAt: collectionRecord.updatedAt
        )
    }
    
    private func mapSourceToDomain(_ source: SourceRecord, host: HostRecord) throws -> Source {
        guard let sourceId = source.id else {
            throw SystemError.mappingFailed(reason: "Source ID is nil")
        }
        
        let auth = mapAuthType(source.authType)
        let search = Search(
            supportedSorts: [],
            supportedFilters: [],
            tags: [],
            presets: []
        )
        
        return Source(
            id: sourceId.rawValue,
            slug: source.slug,
            name: source.name,
            icon: source.icon,
            url: source.url,
            repository: host.repository,
            pinned: source.pinned,
            disabled: source.disabled,
            host: "@\(host.author)/\(host.name)",
            auth: auth,
            search: search,
            presets: [],
            languages: source.languages
        )
    }
    
    private func mapAuthType(_ authType: AuthType?) -> Auth {
        guard let authType = authType else { return .none }
        
        switch authType {
        case .none: return .none
        case .basic: return .basic(fields: BasicAuthFields(username: "", password: ""))
        case .session: return .session(fields: SessionAuthFields(username: "", password: ""))
        case .apiKey: return .apiKey(fields: ApiKeyAuthFields(apiKey: ""))
        case .bearer: return .bearer(fields: BearerAuthFields(token: ""))
        case .cookie: return .cookie(fields: CookieAuthFields(cookie: ""))
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> Error {
        if let domainError = error as? DomainError {
            return domainError
        } else if let storageError = error as? StorageError {
            return storageError.toDomainError()
        } else if let networkError = error as? NetworkError {
            return networkError.toDomainError()
        } else if let dbError = error as? DatabaseError {
            return StorageError.from(grdbError: dbError, context: "getMangaDetails").toDomainError()
        } else {
            return DataAccessError.storageFailure(
                reason: "Failed to fetch manga details",
                underlying: error
            )
        }
    }
}

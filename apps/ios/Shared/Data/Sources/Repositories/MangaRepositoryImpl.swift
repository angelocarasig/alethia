//
//  MangaRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import Domain
import GRDB

public final class MangaRepositoryImpl: MangaRepository {
    private let local: MangaLocalDataSource
    private let remote: MangaRemoteDataSource
    
    public init() {
        self.local = MangaLocalDataSourceImpl()
        self.remote = MangaRemoteDataSourceImpl()
    }
    
    // MARK: - Public Interface
    
    public func getManga(entry: Entry) -> AsyncStream<Result<[Manga], Error>> {
        return AsyncStream { continuation in
            var hasFetchedRemote = false
            
            let task = Task {
                for await mangaBundles in local.getAllManga(for: entry) {
                    if Task.isCancelled { break }
                    
                    if !mangaBundles.isEmpty {
                        let result = mapBundlesToResult(mangaBundles)
                        continuation.yield(result)
                    } else if !hasFetchedRemote {
                        hasFetchedRemote = true
                        
                        Task {
                            await fetchAndSaveFromRemote(entry: entry, continuation: continuation)
                        }
                    }
                }
                
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - Remote Fetching

private extension MangaRepositoryImpl {
    func fetchAndSaveFromRemote(
        entry: Entry,
        continuation: AsyncStream<Result<[Manga], Error>>.Continuation
    ) async {
        do {
            guard let sourceId = entry.sourceId else {
                throw RepositoryError.mappingFailed(reason: "entry must have source id for remote fetch")
            }
            
            let (source, host) = try await local.getSourceAndHost(sourceId: sourceId)
            
            async let mangaDTO = remote.fetchManga(
                sourceSlug: source.slug,
                entrySlug: entry.slug,
                hostURL: host.url
            )
            
            async let chaptersDTO = remote.fetchChapters(
                sourceSlug: source.slug,
                entrySlug: entry.slug,
                hostURL: host.url
            )
            
            let (manga, chapters) = try await (mangaDTO, chaptersDTO)
            
            try await local.saveManga(
                from: manga,
                chapters: chapters,
                entry: entry,
                sourceId: sourceId
            )
            
        } catch let error as RepositoryError {
            continuation.yield(.failure(error.toDomainError()))
        } catch let error as NetworkError {
            continuation.yield(.failure(error.toDomainError()))
        } catch let error as StorageError {
            continuation.yield(.failure(error.toDomainError()))
        } catch let dbError as DatabaseError {
            continuation.yield(.failure(RepositoryError.fromGRDB(dbError).toDomainError()))
        } catch let error as BusinessError {
            continuation.yield(.failure(error))
        } catch let error as DataAccessError {
            continuation.yield(.failure(error))
        } catch let error as SystemError {
            continuation.yield(.failure(error))
        } catch {
            continuation.yield(.failure(DataAccessError.networkFailure(
                reason: "Failed to fetch manga details",
                underlying: error
            )))
        }
    }
}

// MARK: - Bundle Mapping

private extension MangaRepositoryImpl {
    func mapBundlesToResult(_ bundles: [MangaDataBundle]) -> Result<[Manga], Error> {
        do {
            let mangaEntities = try bundles.map(mapBundleToEntity)
            return .success(mangaEntities)
        } catch let error as RepositoryError {
            return .failure(error.toDomainError())
        } catch {
            return .failure(SystemError.mappingFailed(
                reason: "Failed to map manga bundles: \(error.localizedDescription)"
            ))
        }
    }
    
    func mapBundleToEntity(_ bundle: MangaDataBundle) throws -> Manga {
        guard let mangaId = bundle.manga.id else {
            throw RepositoryError.mappingFailed(reason: "manga id is nil")
        }
        
        let authorNames = bundle.authors.map(\.name)
        let tagNames = bundle.tags.filter(\.isCanonical).map(\.displayName)
        let coverURLs = sortAndMapCovers(bundle.covers)
        let altTitles = bundle.alternativeTitles.map(\.title)
        
        let originEntities = try bundle.origins.map { origin in
            try mapOriginToEntity(origin, sources: bundle.sources)
        }
        
        let chapterEntities = bundle.chapters.compactMap(mapChapterToEntity)
        let collections = try bundle.collections.map(mapCollectionToEntity)
        
        let attributedSynopsis = parseMarkdownSynopsis(bundle.manga.synopsis)
        
        return Manga(
            id: mangaId.rawValue,
            title: bundle.manga.title,
            authors: authorNames,
            synopsis: attributedSynopsis,
            alternativeTitles: altTitles,
            tags: tagNames,
            covers: coverURLs,
            origins: originEntities,
            chapters: chapterEntities,
            collections: collections,
            inLibrary: bundle.manga.inLibrary,
            addedAt: bundle.manga.addedAt,
            updatedAt: bundle.manga.updatedAt,
            lastFetchedAt: bundle.manga.lastFetchedAt,
            lastReadAt: bundle.manga.lastReadAt,
            orientation: bundle.manga.orientation,
            showAllChapters: bundle.manga.showAllChapters,
            showHalfChapters: bundle.manga.showHalfChapters
        )
    }
}

// MARK: - Entity Mapping Helpers

private extension MangaRepositoryImpl {
    func sortAndMapCovers(_ covers: [CoverRecord]) -> [URL] {
        covers
            .sorted { lhs, rhs in
                if lhs.isPrimary != rhs.isPrimary {
                    return lhs.isPrimary
                }
                return (lhs.id?.rawValue ?? 0) < (rhs.id?.rawValue ?? 0)
            }
            .map(\.localPath)
    }
    
    func mapOriginToEntity(
        _ origin: OriginRecord,
        sources: [OriginRecord.ID: (source: SourceRecord, host: HostRecord)]
    ) throws -> Origin {
        guard let originId = origin.id else {
            throw RepositoryError.mappingFailed(reason: "origin id is nil")
        }
        
        let domainSource: Source? = try sources[originId].map { (sourceRecord, hostRecord) in
            try mapSourceRecordToDomain(sourceRecord, host: hostRecord)
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
    
    func mapChapterToEntity(_ enriched: ChapterWithMetadata) -> Chapter? {
        guard let chapterId = enriched.chapter.id else { return nil }
        
        return Chapter(
            id: chapterId.rawValue,
            slug: enriched.chapter.slug,
            title: enriched.chapter.title,
            number: enriched.chapter.number,
            date: enriched.chapter.date,
            scanlator: enriched.scanlatorName,
            language: enriched.chapter.language,
            url: enriched.chapter.url.absoluteString,
            icon: enriched.sourceIcon,
            progress: enriched.chapter.progress
        )
    }
    
    func mapCollectionToEntity(_ tuple: (collection: CollectionRecord, count: Int)) throws -> Collection {
        guard let collectionId = tuple.collection.id else {
            throw RepositoryError.mappingFailed(reason: "collection id is nil")
        }
        
        return Collection(
            id: collectionId.rawValue,
            name: tuple.collection.name,
            description: tuple.collection.description ?? "",
            count: tuple.count,
            createdAt: tuple.collection.createdAt,
            updatedAt: tuple.collection.updatedAt
        )
    }
    
    func parseMarkdownSynopsis(_ synopsis: String) -> AttributedString {
        do {
            return try AttributedString(
                markdown: synopsis,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
        } catch {
            return AttributedString(synopsis)
        }
    }
}

// MARK: - Source Mapping

private extension MangaRepositoryImpl {
    func mapSourceRecordToDomain(_ sourceRecord: SourceRecord, host: HostRecord) throws -> Source {
        guard let sourceId = sourceRecord.id else {
            throw RepositoryError.mappingFailed(reason: "source id is nil")
        }
        
        guard host.id != nil else {
            throw RepositoryError.mappingFailed(reason: "host id is nil")
        }
        
        let auth = mapAuthType(sourceRecord.authType)
        
        // simplified search - origin doesn't need full search details
        let search = Search(
            supportedSorts: [],
            supportedFilters: [],
            tags: [],
            presets: []
        )
        
        let hostDisplayName = "@\(host.author)/\(host.name)"
        
        return Source(
            id: sourceId.rawValue,
            slug: sourceRecord.slug,
            name: sourceRecord.name,
            icon: sourceRecord.icon,
            url: sourceRecord.url,
            repository: host.repository,
            pinned: sourceRecord.pinned,
            disabled: sourceRecord.disabled,
            host: hostDisplayName,
            auth: auth,
            search: search,
            presets: [],
            languages: sourceRecord.languages
        )
    }
    
    func mapAuthType(_ authType: AuthType?) -> Auth {
        guard let authType = authType else { return .none }
        
        switch authType {
        case .none:
            return .none
        case .basic:
            return .basic(fields: BasicAuthFields(username: "", password: ""))
        case .session:
            return .session(fields: SessionAuthFields(username: "", password: ""))
        case .apiKey:
            return .apiKey(fields: ApiKeyAuthFields(apiKey: ""))
        case .bearer:
            return .bearer(fields: BearerAuthFields(token: ""))
        case .cookie:
            return .cookie(fields: CookieAuthFields(cookie: ""))
        }
    }
}

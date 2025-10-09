//
//  MangaRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation
import Domain

public final class MangaRepositoryImpl: MangaRepository {
    private let local: MangaLocalDataSource
    private let remote: MangaRemoteDataSource
    
    public init() {
        self.local = MangaLocalDataSourceImpl()
        self.remote = MangaRemoteDataSourceImpl()
    }
    
    public func getManga(entry: Entry) -> AsyncStream<Result<[Manga], Error>> {
        return AsyncStream { continuation in
            let task = Task {
                var hasFetchedRemote = false
                
                for await mangaBundles in local.getAllManga(for: entry) {
                    if Task.isCancelled { break }
                    
                    if !mangaBundles.isEmpty {
                        do {
                            let mangaEntities = try self.mapBundlesToEntities(mangaBundles)
                            continuation.yield(.success(mangaEntities))
                        } catch {
                            continuation.yield(.failure(error))
                        }
                    } else if !hasFetchedRemote {
                        hasFetchedRemote = true
                        
                        Task {
                            do {
                                try await self.fetchAndSaveFromRemote(entry: entry)
                            } catch {
                                continuation.yield(.failure(error))
                            }
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
    
    // MARK: - Private Helper Methods
    
    private func fetchAndSaveFromRemote(entry: Entry) async throws {
        guard let sourceId = entry.sourceId else {
            throw RepositoryError.mappingError(reason: "entry must have source id for remote fetch")
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
    }
    
    private func mapBundlesToEntities(_ bundles: [MangaDataBundle]) throws -> [Manga] {
        return try bundles.map { bundle in
            guard let mangaId = bundle.manga.id else {
                throw RepositoryError.mappingError(reason: "manga id is nil")
            }
            
            let authorNames = bundle.authors.map { $0.name }
            
            let tagNames = bundle.tags
                .filter { $0.isCanonical }
                .map { $0.displayName }
            
            let coverURLs = bundle.covers
                .sorted { lhs, rhs in
                    if lhs.isPrimary != rhs.isPrimary {
                        return lhs.isPrimary
                    }
                    return (lhs.id?.rawValue ?? 0) < (rhs.id?.rawValue ?? 0)
                }
                .map { $0.localPath }
            
            let altTitles = bundle.alternativeTitles.map { $0.title }
            
            let originEntities = try bundle.origins.map { origin in
                guard let originId = origin.id else {
                    throw RepositoryError.mappingError(reason: "origin id is nil")
                }
                
                let domainSource: Source? = try bundle.sources[originId].map { (sourceRecord, hostRecord) in
                    try self.mapSourceRecordToDomain(sourceRecord, host: hostRecord)
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
            
            let chapterEntities = bundle.chapters.compactMap { enriched -> Chapter? in
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
            
            return Manga(
                id: mangaId.rawValue,
                title: bundle.manga.title,
                authors: authorNames,
                synopsis: bundle.manga.synopsis,
                alternativeTitles: altTitles,
                tags: tagNames,
                covers: coverURLs,
                origins: originEntities,
                chapters: chapterEntities,
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
    
    private func mapSourceRecordToDomain(_ sourceRecord: SourceRecord, host: HostRecord) throws -> Source {
        guard let sourceId = sourceRecord.id else {
            throw RepositoryError.mappingError(reason: "source id is nil")
        }
        
        guard let hostId = host.id else {
            throw RepositoryError.mappingError(reason: "host id is nil")
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
            presets: []
        )
    }
    
    private func mapAuthType(_ authType: AuthType?) -> Auth {
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

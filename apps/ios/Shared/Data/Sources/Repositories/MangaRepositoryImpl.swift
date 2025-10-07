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
            throw RepositoryError.mappingError(reason: "Entry must have source ID for remote fetch")
        }
        
        // get source and host from local data source
        let (source, host) = try await local.getSourceAndHost(sourceId: sourceId)
        
        // fetch manga and chapters from remote concurrently
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
        
        // save to database - this will trigger the observation
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
                throw RepositoryError.mappingError(reason: "Manga ID is nil")
            }
            
            // map authors
            let authorNames = bundle.authors.map { $0.name }
            
            // map tags - filter for canonical only
            let tagNames = bundle.tags
                .filter { $0.isCanonical }
                .map { $0.displayName }
            
            // map covers - sort by primary and id
            let coverURLs = bundle.covers
                .sorted { lhs, rhs in
                    if lhs.isPrimary != rhs.isPrimary {
                        return lhs.isPrimary
                    }
                    return (lhs.id?.rawValue ?? 0) < (rhs.id?.rawValue ?? 0)
                }
                .map { $0.localPath }
            
            // map alternative titles
            let altTitles = bundle.alternativeTitles.map { $0.title }
            
            // map origins
            let originEntities = try bundle.origins.map { origin in
                guard let originId = origin.id else {
                    throw RepositoryError.mappingError(reason: "Origin ID is nil")
                }
                
                return Origin(
                    id: originId.rawValue,
                    slug: origin.slug,
                    url: URL(string: origin.url)!,
                    priority: origin.priority,
                    classification: origin.classification,
                    status: origin.status
                )
            }
            
            // map chapters - all metadata already provided by data source
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
}

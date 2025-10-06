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
    private let database: DatabaseConfiguration
    
    public init() {
        self.local = MangaLocalDataSourceImpl()
        self.remote = MangaRemoteDataSourceImpl()
        self.database = DatabaseConfiguration.shared
    }
    
    public func getManga(entry: Domain.Entry) -> AsyncStream<Result<[Manga], any Error>> {
        AsyncStream { continuation in
            let task = Task {
                var hasFetchedRemote = false
                
                for await mangaData in local.getAllManga(for: entry) {
                    if Task.isCancelled { break }
                    
                    // if we have local data, return it
                    if !mangaData.isEmpty {
                        do {
                            let mangaEntities = try self.mapRecordsToEntities(mangaData)
                            continuation.yield(.success(mangaEntities))
                        } catch {
                            continuation.yield(.failure(error))
                        }
                    } else if !hasFetchedRemote {
                        // no local data, fetch from remote
                        hasFetchedRemote = true
                        
                        do {
                            // entry must have source id for remote fetch
                            guard let sourceId = entry.sourceId else {
                                throw RepositoryError.mappingError(reason: "Entry must have source ID for remote fetch")
                            }
                            
                            // get source and host information
                            let (source, host) = try await self.getSourceAndHost(sourceId: sourceId)
                            
                            // fetch manga and chapters from remote
                            let mangaDTO = try await remote.fetchManga(
                                sourceSlug: source.slug,
                                entrySlug: entry.slug,
                                hostURL: host.url
                            )
                            
                            let chaptersDTO = try await remote.fetchChapters(
                                sourceSlug: source.slug,
                                entrySlug: entry.slug,
                                hostURL: host.url
                            )
                            
                            // save to database
                            let savedManga = try await local.saveManga(
                                from: mangaDTO,
                                chapters: chaptersDTO,
                                entry: entry,
                                sourceId: sourceId
                            )
                            
                            // fetch the complete data again to get all relationships
                            // this will trigger the observation and emit the saved manga
                        } catch {
                            continuation.yield(.failure(error))
                            continuation.finish()
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
    
    private func getSourceAndHost(sourceId: Int64) async throws -> (SourceRecord, HostRecord) {
        try await database.reader.read { db in
            guard let source = try SourceRecord.fetchOne(db, key: SourceRecord.ID(rawValue: sourceId)) else {
                throw RepositoryError.mappingError(reason: "Source not found")
            }
            
            guard let host = try source.host.fetchOne(db) else {
                throw RepositoryError.hostNotFound
            }
            
            return (source, host)
        }
    }
    
    private func mapRecordsToEntities(_ data: [(MangaRecord, [AuthorRecord], [TagRecord], [CoverRecord], [AlternativeTitleRecord], [OriginRecord], [ChapterRecord])]) throws -> [Manga] {
        try data.map { (manga, authors, tags, covers, alternativeTitles, origins, chapters) in
            guard let mangaId = manga.id else {
                throw RepositoryError.mappingError(reason: "Manga ID is nil")
            }
            
            // map authors
            let authorNames = authors.map { $0.name }
            
            // map tags (only canonical ones)
            let tagNames = tags
                .filter { $0.isCanonical }
                .map { $0.displayName }
            
            // map covers
            let coverURLs = covers
                .sorted { ($0.isPrimary && !$1.isPrimary) || (!$0.isPrimary && !$1.isPrimary && $0.id?.rawValue ?? 0 < $1.id?.rawValue ?? 0) }
                .map { $0.localPath }
            
            // map alternative titles
            let altTitles = alternativeTitles.map { $0.title }
            
            // map origins
            let originEntities = try origins.map { origin in
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
            
            // map chapters
            let chapterEntities = try chapters.map { chapter in
                guard let chapterId = chapter.id else {
                    throw RepositoryError.mappingError(reason: "Chapter ID is nil")
                }
                
                // todo: fetch scanlator name and source icon
                return Chapter(
                    id: chapterId.rawValue,
                    slug: chapter.slug,
                    title: chapter.title,
                    number: chapter.number,
                    date: chapter.date,
                    scanlator: "", // todo: fetch from scanlator record
                    language: chapter.language,
                    url: chapter.url.absoluteString,
                    icon: nil, // todo: fetch from source through origin
                    progress: chapter.progress
                )
            }
            
            return Manga(
                id: mangaId.rawValue,
                title: manga.title,
                authors: authorNames,
                synopsis: manga.synopsis,
                alternativeTitles: altTitles,
                tags: tagNames,
                covers: coverURLs,
                origins: originEntities,
                chapters: chapterEntities,
                inLibrary: manga.inLibrary,
                addedAt: manga.addedAt,
                updatedAt: manga.updatedAt,
                lastFetchedAt: manga.lastFetchedAt,
                lastReadAt: manga.lastReadAt,
                orientation: manga.orientation,
                showAllChapters: manga.showAllChapters,
                showHalfChapters: manga.showHalfChapters
            )
        }
    }
}

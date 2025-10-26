import Foundation
import Domain
import GRDB

public final class FindMatchesUseCaseImpl: FindMatchesUseCase {
    private let repository: LibraryRepository
    private let database: DatabaseConfiguration
    
    public init(repository: LibraryRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(for raw: [Entry]) -> AsyncStream<Result<[Entry], Error>> {
        AsyncStream { continuation in
            // use value observation to monitor changes in match state
            let observation = ValueObservation.tracking { [weak self] db -> [Entry] in
                guard let self else { return [] }
                
                var enrichedEntries: [Entry] = []
                enrichedEntries.reserveCapacity(raw.count)
                
                for entry in raw {
                    do {
                        let enriched = try self.matchEntry(entry, in: db)
                        enrichedEntries.append(enriched)
                    } catch {
                        // if matching fails for an entry, return it with verification failed state
                        enrichedEntries.append(Entry(
                            mangaId: nil,
                            sourceId: entry.sourceId,
                            slug: entry.slug,
                            title: entry.title,
                            cover: entry.cover,
                            state: .matchVerificationFailed,
                            unread: 0
                        ))
                    }
                }
                
                return enrichedEntries
            }
            
            let task = Task {
                do {
                    for try await enriched in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(enriched))
                    }
                } catch let dbError as DatabaseError {
                    continuation.yield(.failure(StorageError.from(grdbError: dbError, context: "findMatches")))
                } catch let error as StorageError {
                    continuation.yield(.failure(error))
                } catch {
                    continuation.yield(.failure(StorageError.queryFailed(sql: "findMatches", error: error)))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Private Matching Logic
    
    private func matchEntry(_ entry: Entry, in db: Database) throws -> Entry {
        // step 1: try slug matching (highest priority)
        let slugMatches = try repository.fetchManga(bySlug: entry.slug, in: db)
        
        if slugMatches.count == 1 {
            guard let manga = slugMatches[0] as? MangaRecord,
                  let mangaId = manga.id else {
                throw StorageError.invalidCast(expected: "MangaRecord", actual: String(describing: type(of: slugMatches[0])))
            }
            
            let origins = try repository.fetchOrigins(mangaId: mangaId.rawValue, in: db)
            let hasSameSource = origins.contains { originAny -> Bool in
                guard let origin = originAny as? OriginRecord else { return false }
                return origin.sourceId?.rawValue == entry.sourceId
            }
            
            if hasSameSource {
                return Entry(
                    mangaId: mangaId.rawValue,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .exactMatch,
                    unread: 0
                )
            } else {
                return Entry(
                    mangaId: mangaId.rawValue,
                    sourceId: entry.sourceId,
                    slug: entry.slug,
                    title: entry.title,
                    cover: entry.cover,
                    state: .crossSourceMatch,
                    unread: 0
                )
            }
        } else if slugMatches.count > 1 {
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .matchVerificationFailed,
                unread: 0
            )
        }
        
        // step 2: try title matching (fallback)
        let titleMatches = try repository.fetchManga(byTitle: entry.title, in: db)
        
        if titleMatches.isEmpty {
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .noMatch,
                unread: 0
            )
        }
        
        // check which matches have same source
        var sameSourceMatches: [Any] = []
        for mangaAny in titleMatches {
            guard let manga = mangaAny as? MangaRecord,
                  let mangaId = manga.id else { continue }
            
            let origins = try repository.fetchOrigins(mangaId: mangaId.rawValue, in: db)
            let hasSameSource = origins.contains { originAny -> Bool in
                guard let origin = originAny as? OriginRecord else { return false }
                return origin.sourceId?.rawValue == entry.sourceId
            }
            
            if hasSameSource {
                sameSourceMatches.append(mangaAny)
            }
        }
        
        if sameSourceMatches.count == 1 {
            guard let manga = sameSourceMatches[0] as? MangaRecord,
                  let mangaId = manga.id else {
                throw StorageError.invalidCast(expected: "MangaRecord", actual: String(describing: type(of: sameSourceMatches[0])))
            }
            
            return Entry(
                mangaId: mangaId.rawValue,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .titleMatchSameSource,
                unread: 0
            )
        } else if sameSourceMatches.count > 1 {
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .titleMatchSameSourceAmbiguous,
                unread: 0
            )
        } else {
            return Entry(
                mangaId: nil,
                sourceId: entry.sourceId,
                slug: entry.slug,
                title: entry.title,
                cover: entry.cover,
                state: .titleMatchDifferentSource,
                unread: 0
            )
        }
    }
}

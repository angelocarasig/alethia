//
//  ChapterRepositoryImpl.swift
//  Data
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation
import Domain
import GRDB

public final class ChapterRepositoryImpl: ChapterRepository {
    private let local: ChapterLocalDataSource
    private let remote: ChapterRemoteDataSource
    
    public init() {
        self.local = ChapterLocalDataSourceImpl()
        self.remote = ChapterRemoteDataSourceImpl()
    }
    
    public func getChapterContents(chapterId: Int64) async throws -> [String] {
        do {
            // get chapter metadata from local database
            let (chapterSlug, mangaId, sourceSlug, hostUrl) = try await local.getChapterRequestInfo(chapterId: chapterId)
            
            // fetch contents from remote
            return try await remote.fetchChapterContents(
                sourceSlug: sourceSlug,
                mangaId: mangaId,
                chapterSlug: chapterSlug,
                hostURL: hostUrl
            )
        } catch let error as RepositoryError {
            throw error.toDomainError()
        } catch let error as NetworkError {
            throw error.toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch let dbError as DatabaseError {
            throw RepositoryError.fromGRDB(dbError).toDomainError()
        } catch {
            throw DataAccessError.networkFailure(reason: "Failed to fetch chapter contents", underlying: error)
        }
    }
}

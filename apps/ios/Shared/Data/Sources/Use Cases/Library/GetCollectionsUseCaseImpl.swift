//
//  GetCollectionsUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 17/10/2025.
//

import Foundation
import Domain
import GRDB

public final class GetCollectionsUseCaseImpl: GetCollectionsUseCase {
    private let repository: LibraryRepository
    private let database: DatabaseConfiguration
    
    public init(repository: LibraryRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute() -> AsyncStream<Result<[Domain.Collection], any Error>> {
        AsyncStream { continuation in
            let repository = self.repository
            
            let observation = ValueObservation.tracking { db -> [Domain.Collection] in
                do {
                    let collectionsWithCounts = try repository.fetchCollections(in: db)
                    
                    return try collectionsWithCounts.map { tuple in
                        guard let collection = tuple.collection as? CollectionRecord else {
                            throw SystemError.mappingFailed(reason: "Invalid collection record type")
                        }
                        
                        guard let collectionId = collection.id else {
                            throw SystemError.mappingFailed(reason: "Collection ID is nil")
                        }
                        
                        return Domain.Collection(
                            id: collectionId.rawValue,
                            name: collection.name,
                            description: collection.description ?? "",
                            count: tuple.count,
                            createdAt: collection.createdAt,
                            updatedAt: collection.updatedAt
                        )
                    }
                } catch {
                    throw error
                }
            }
            
            let database = self.database
            
            let task = Task {
                do {
                    for try await collections in observation.values(in: database.reader) {
                        if Task.isCancelled { break }
                        continuation.yield(.success(collections))
                    }
                } catch let domainError as DomainError {
                    continuation.yield(.failure(domainError))
                } catch let storageError as StorageError {
                    continuation.yield(.failure(storageError.toDomainError()))
                } catch let dbError as DatabaseError {
                    continuation.yield(.failure(StorageError.from(grdbError: dbError, context: "getCollections").toDomainError()))
                } catch {
                    continuation.yield(.failure(DataAccessError.storageFailure(
                        reason: "Failed to fetch collections",
                        underlying: error
                    )))
                }
                continuation.finish()
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

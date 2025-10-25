//
//  ValidateHostURLUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import GRDB

public final class ValidateHostURLUseCaseImpl: ValidateHostURLUseCase {
    private let repository: HostRepository
    private let database: DatabaseConfiguration
    
    public init(repository: HostRepository) {
        self.repository = repository
        self.database = DatabaseConfiguration.shared
    }
    
    public func execute(url: URL) async throws -> HostDTO {
        // validate url format
        guard url.scheme == "https" || url.scheme == "http" else {
            throw BusinessError.invalidURLFormat(url: url.absoluteString)
        }
        
        // fetch manifest from remote
        let dto = try await repository.remoteManifest(from: url.trailingSlash(.remove))
        
        // validate host configuration
        guard !dto.name.isEmpty else {
            throw BusinessError.invalidHostConfiguration(reason: "Host name is empty")
        }
        
        guard !dto.author.isEmpty else {
            throw BusinessError.invalidHostConfiguration(reason: "Host author is empty")
        }
        
        guard !dto.sources.isEmpty else {
            throw BusinessError.noSourcesInHost
        }
        
        for source in dto.sources {
            guard !source.name.isEmpty else {
                throw BusinessError.invalidHostConfiguration(reason: "Source name is empty for \(source.slug)")
            }
            
            guard !source.slug.isEmpty else {
                throw BusinessError.invalidHostConfiguration(reason: "Source slug is empty")
            }
            
            guard URL(string: source.url) != nil else {
                throw BusinessError.invalidHostConfiguration(reason: "Invalid URL for source \(source.slug)")
            }
        }
        
        // check if host already exists in database
        do {
            let exists = try await database.reader.read { db in
                try self.repository.hostExists(repository: dto.repository, in: db)
            }
            
            if exists {
                throw BusinessError.hostAlreadyExists(repository: URL(string: dto.repository)!)
            }
            
        } catch let error as BusinessError {
            throw error
        } catch let dbError as DatabaseError {
            throw StorageError.from(grdbError: dbError, context: "validateHost").toDomainError()
        } catch let error as StorageError {
            throw error.toDomainError()
        } catch {
            // if we can't check the database, still return the dto
            // the save operation will handle duplicate checking
        }
        
        return dto
    }
}

//
//  HostManifest.swift
//  Domain
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

/// Represents the manifest data retrieved from a host URL.
/// Contains metadata about the host including its sources, author information,
/// and validation status. Used as an intermediate representation between
/// fetching host data and persisting it to the database.
public struct HostManifest: Codable, Sendable {
    public let name: String
    public let author: String
    public let repository: URL
    public let sources: [SourceManifest]
    
    public init(
        name: String,
        author: String,
        repository: URL,
        sources: [SourceManifest]
    ) {
        self.name = name
        self.author = author
        self.repository = repository
        self.sources = sources
    }
}

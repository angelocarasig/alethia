//
//  Host.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Host: Sendable {
    public let id: Int64
    
    public let name: String
    
    public let author: String
    
    public let url: URL
    
    public let repository: URL
    
    public let official: Bool

    public let sources: [Source]
    
    public var displayName: String {
        "@\(author.lowercased())/\(name.lowercased())"
    }
    
    public init(id: Int64, name: String, author: String, url: URL, repository: URL, official: Bool, sources: [Source]) {
        self.id = id
        self.name = name
        self.author = author
        self.url = url
        self.repository = repository
        self.official = official
        self.sources = sources
    }
}

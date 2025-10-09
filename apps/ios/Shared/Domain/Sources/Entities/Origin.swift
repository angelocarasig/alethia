//
//  Origin.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Origin: Sendable {
    /// Unique identifier
    public let id: Int64
    
    /// URL-safe string for building requests
    public let slug: String
    
    /// URL to the specific source's origin's URL
    public let url: URL
    
    /// Its priority position in relation to its associated manga
    public let priority: Int
    
    /// Source-specific classification value
    public let classification: Classification
    
    /// Source-specific status value
    public let status: Status
    
    public let source: Source?
    
    public init(
        id: Int64,
        slug: String,
        url: URL,
        priority: Int,
        classification: Classification,
        status: Status,
        source: Source?
    ) {
        self.id = id
        self.slug = slug
        self.url = url
        self.priority = priority
        self.classification = classification
        self.status = status
        self.source = source
    }
}

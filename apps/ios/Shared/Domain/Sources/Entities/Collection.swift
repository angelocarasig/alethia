//
//  Collection.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Collection: Sendable {
    public let id: Int64
    
    public let name: String
    public let description: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(id: Int64, name: String, description: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

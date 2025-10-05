//
//  SourceSearchDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct SourceSearchDTO: Codable, Sendable {
    public let sort: [Search.Options.Sort]
    public let filters: [Search.Options.Filter]
    public let tags: [SearchTagDTO]
}

public struct SearchTagDTO: Codable, Sendable {
    public let slug: String
    public let name: String
    public let nsfw: Bool
}

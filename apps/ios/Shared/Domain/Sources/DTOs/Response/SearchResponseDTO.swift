//
//  SearchResponseDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct SearchResponseDTO: Codable {
    public let results: [EntryDTO]
    public let page: Int
    public let more: Bool
}

public struct EntryDTO: Codable {
    public let slug: String
    public let title: String
    public let cover: String?
}

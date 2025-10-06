//
//  MangaDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 7/10/2025.
//

import Foundation

public struct MangaDTO: Codable, Sendable {
    public let slug: String
    public let title: String
    public let authors: [String]
    public let alternativeTitles: [String]
    public let synopsis: String
    public let createdAt: Date
    public let updatedAt: Date
    public let classification: String
    public let publication: String
    public let tags: [String]
    public let covers: [String]
    public let url: String
}

public struct ChapterDTO: Codable, Sendable {
    public let slug: String
    public let title: String
    public let number: Double
    public let scanlator: String
    public let language: String
    public let url: String
    public let date: Date
}

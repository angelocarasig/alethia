//
//  SourceDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct SourceDTO: Codable, Sendable {
    public let name: String
    public let slug: String
    public let icon: String
    public let languages: [LanguageCode]
    public let nsfw: Bool
    public let url: String
    public let referer: String
    public let auth: SourceAuthDTO
    public let search: SourceSearchDTO
    public let presets: [SourcePresetDTO]
}

//
//  SourceAuthDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct SourceAuthDTO: Codable, Sendable {
    public let type: AuthType
    public let required: Bool
}

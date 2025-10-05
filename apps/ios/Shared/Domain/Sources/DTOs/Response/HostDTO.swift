//
//  HostDTO.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

public struct HostDTO: Codable, Sendable {
    public let name: String
    public let author: String
    public let repository: String
    public let sources: [SourceDTO]
}

//
//  HostDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation

struct HostDTO: Codable {
    let name: String
    let author: String
    let website: String
    let sources: [SourceDTO]
}

struct SourceDTO: Codable {
    let name: String
    let icon: String
    let path: String
}

struct SourceRouteDTO: Codable {
    let name: String
    let path: String
}

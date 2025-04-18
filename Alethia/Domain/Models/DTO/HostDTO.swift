//
//  HostDTO.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation

struct HostDTO: Codable {
    let name: String
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

let mockHostDTO: HostDTO = HostDTO(
    name: randomString(length: 10),
    sources: [
        SourceDTO(
            name: randomString(length: 10),
            icon: randomString(length: 10),
            path: randomString(length: 10)
        )
    ]
)

let mockSourceRouteDTO: [SourceRouteDTO] = [
    SourceRouteDTO(
        name: randomString(length: 10),
        path: randomString(length: 10)
    ),
    SourceRouteDTO(
        name: randomString(length: 10),
        path: randomString(length: 10)
    )
]

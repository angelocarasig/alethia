//
//  NewHostPayload.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

internal typealias NewHostPayload = Domain.Models.Presentation.NewHostPayload

public extension Domain.Models.Presentation {
    struct NewHostPayload {
        var name: String
        var author: String
        var repository: String
        var baseUrl: String
        var sources: [NewHostPayload.Source]
        
        struct Source {
            let name: String
            let path: String
            let icon: String
            let website: String
            let description: String
            let paths: [NewHostPayload.SourceRoute]
        }
        
        struct SourceRoute {
            let name: String
            let path: String
        }
        
        init(name: String, author: String, repository: String, baseUrl: String) {
            self.name = name
            self.author = author
            self.repository = repository
            self.baseUrl = baseUrl
            self.sources = []
        }
    }
}

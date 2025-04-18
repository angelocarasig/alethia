//
//  NewHostPayload.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

struct NewHostPayload {
    var name: String
    var baseUrl: String
    var sources: [NewHostPayload.Source]
    
    struct Source {
        let name: String
        let path: String
        let icon: String
        let paths: [NewHostPayload.SourceRoute]
    }
    
    struct SourceRoute {
        let name: String
        let path: String
    }
    
    init(name: String, baseUrl: String) {
        self.name = name
        self.baseUrl = baseUrl
        self.sources = []
    }
}

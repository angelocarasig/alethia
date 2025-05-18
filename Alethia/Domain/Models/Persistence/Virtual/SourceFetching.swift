//
//  SourceFetching.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

struct SourceFetching: Decodable, FetchableRecord {
    var host: Host
    var source: Source
    var route: SourceRoute
    
    var fetchUrl: String {
        URL.appendingPaths(host.baseUrl, source.path, route.path)!.absoluteString
    }
    
    func itemUrl(_ slug: Slug) -> String {
        URL.appendingPaths(host.baseUrl, source.path, "manga", slug)!.absoluteString
    }
}

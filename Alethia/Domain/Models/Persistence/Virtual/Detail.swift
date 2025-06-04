//
//  Detail.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

struct Detail: Decodable, FetchableRecord {
    var manga: Manga
    var titles: [Title]
    var covers: [Cover]
    var authors: [Author]
    var tags: [Tag]
    var origins: [OriginExtended]
    var chapters: [ChapterExtended]
    var collections: [Collection]
}

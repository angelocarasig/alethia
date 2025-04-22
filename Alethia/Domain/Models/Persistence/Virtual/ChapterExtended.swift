//
//  ChapterWithSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

struct ChapterExtended: Decodable, FetchableRecord {
    var chapter: Chapter
    var scanlator: Scanlator
    var origin: Origin
    var source: Source? // as origin can be detached
}

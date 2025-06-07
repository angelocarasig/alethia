//
//  DetailPriorities.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/6/2025.
//

import Foundation
import GRDB

/// Wrapper for all of a manga's origins/scanlator priorities
struct DetailPriorities: Decodable, FetchableRecord {
    var origins: [OriginExtended]
    var scanlators: [ScanlatorExtended]
}

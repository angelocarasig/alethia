//
//  ReadableChapter.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// protocol for types that can be used as chapters in the reader
public protocol ReadableChapter: Sendable, Identifiable where ID: Hashable & Sendable {
    var id: ID { get }
}

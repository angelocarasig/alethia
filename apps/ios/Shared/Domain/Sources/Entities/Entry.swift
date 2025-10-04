//
//  Entry.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Entry: Sendable {
    public let slug: String

    public let title: String

    /// Location to the remote resource
    public let cover: URL
}

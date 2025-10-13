//
//  Status.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

public enum Status: String, Codable, Sendable, CaseIterable {
    case Unknown
    case Ongoing
    case Completed
    case Hiatus
    case Cancelled
}

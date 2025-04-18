//
//  PublishStatus.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation

enum PublishStatus: String, Codable, CaseIterable {
    case Unknown
    case Ongoing
    case Completed
    case Hiatus
    case Cancelled
}

//
//  OriginError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

enum OriginError: LocalizedError {
    case notFound
    case invalid(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Origin could not be found."
        case .invalid(let description):
            return "Invalid: \(description)"
        }
    }
}

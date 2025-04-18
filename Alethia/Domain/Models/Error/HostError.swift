//
//  HostError.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

enum HostError: LocalizedError {
    case duplicateHost
    
    var errorDescription: String? {
        switch self {
        case .duplicateHost:
            return "Host already exists"
        }
    }
}

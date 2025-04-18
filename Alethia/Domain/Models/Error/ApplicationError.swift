//
//  ApplicationError.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation

enum ApplicationError: LocalizedError {
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .operationCancelled:
            return "The given operation was cancelled."
        }
    }
}

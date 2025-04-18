//
//  NetworkError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case missingURL
    case noConnect
    case invalidData
    case requestFailed
    case encodingError
    case decodingError
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "An Invalid URL was provided."
        case .noConnect:
            return "No connection available."
        case .invalidResponse:
            return "An invalid response was received from server."
        case .invalidData:
            return "Invalid data received."
        case .decodingError:
            return "Failed to decode data received."
        case .encodingError:
            return "Failed to encode data received."
        case .requestFailed:
            return "Network request failed."
        }
    }
}

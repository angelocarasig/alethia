//
//  NetworkError.swift
//  Data
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL(url: String)
    case noInternetConnection
    case invalidResponse(statusCode: Int, response: URLResponse?)
    case decodingError(type: String, error: Error)
    case requestFailed(underlyingError: URLError)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL format: \(url)"
            
        case .noInternetConnection:
            return "No internet connection available. Please check your network settings."
            
        case .invalidResponse(let statusCode, _):
            return "Invalid server response (HTTP \(statusCode))"
            
        case .decodingError(let type, let error):
            return "Failed to decode \(type): \(error.localizedDescription)"
            
        case .requestFailed(let underlyingError):
            return underlyingError.localizedDescription
            
        case .timeout:
            return "Request timed out. Please try again."
        }
    }
}

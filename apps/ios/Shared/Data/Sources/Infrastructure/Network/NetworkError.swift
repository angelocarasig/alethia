//
//  NetworkError.swift
//  Data
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation
import Domain

/// internal network-specific errors
/// these are mapped to DataAccessError at repository boundaries
internal enum NetworkError: LocalizedError {
    case invalidURL(url: String)
    case noInternetConnection
    case invalidResponse(statusCode: Int, response: URLResponse?)
    case decodingError(type: String, error: Error)
    case requestFailed(underlyingError: URLError)
    case timeout
    case cancelled  // add explicit cancellation case
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL format: \(url)"
            
        case .noInternetConnection:
            return "No internet connection available"
            
        case .invalidResponse(let statusCode, _):
            return "Invalid server response (HTTP \(statusCode))"
            
        case .decodingError(let type, let error):
            return "Failed to decode \(type): \(error.localizedDescription)"
            
        case .requestFailed(let underlyingError):
            return underlyingError.localizedDescription
            
        case .timeout:
            return "Request timed out"
            
        case .cancelled:
            return "Request was cancelled"
        }
    }
    
    /// maps internal network error to public domain error
    func toDomainError() -> DataAccessError {
        switch self {
        case .invalidURL(let url):
            return .networkFailure(reason: "Invalid URL: \(url)", underlying: self)
            
        case .noInternetConnection:
            return .networkFailure(reason: "No internet connection", underlying: self)
            
        case .invalidResponse(let statusCode, _):
            return .invalidResponse(statusCode: statusCode)
            
        case .decodingError(let type, let error):
            return .networkFailure(reason: "Failed to decode \(type)", underlying: error)
            
        case .requestFailed(let underlyingError):
            return .networkFailure(reason: underlyingError.localizedDescription, underlying: underlyingError)
            
        case .timeout:
            return .timeout(operation: "network request")
            
        case .cancelled:
            return .cancelled
        }
    }
    
    /// check if this error represents a cancellation
    var isCancellation: Bool {
        switch self {
        case .cancelled:
            return true
        case .requestFailed(let urlError):
            return urlError.code == .cancelled
        default:
            return false
        }
    }
}

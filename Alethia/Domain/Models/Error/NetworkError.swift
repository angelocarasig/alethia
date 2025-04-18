//
//  NetworkError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/4/2025.
//

import Foundation

enum NetworkError: LocalizedError {
    case missingURL
    case invalidURL(url: String)
    case noInternetConnection
    case invalidResponse(statusCode: Int, response: URLResponse?)
    case invalidData(cause: Error?)
    case decodingError(type: String, error: Error)
    case encodingError(type: String, error: Error)
    case requestFailed(underlyingError: URLError)
    case serverError(statusCode: Int, message: String?)
    case timeout
    case authenticationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "The URL was not provided."
            
        case .invalidURL(let url):
            return "Invalid URL format: \(url)"
            
        case .noInternetConnection:
            return "No internet connection available. Please check your network settings."
            
        case .invalidResponse(let statusCode, _):
            return "Invalid server response (HTTP \(statusCode))"
            
        case .invalidData(let cause):
            if let cause = cause {
                return "Received malformed data: \(cause.localizedDescription)"
            }
            return "Received invalid or corrupted data"
            
        case .decodingError(let type, let error):
            return "Failed to decode \(type): \(error.localizedDescription)"
            
        case .encodingError(let type, let error):
            return "Failed to encode \(type): \(error.localizedDescription)"
            
        case .requestFailed(let underlyingError):
            return underlyingError.localizedDescription
            
        case .serverError(let statusCode, let message):
            if let message = message {
                return "Server error \(statusCode): \(message)"
            }
            return "Server error \(statusCode)"
            
        case .timeout:
            return "Request timed out. Please try again."
            
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noInternetConnection, .timeout:
            return "Please check your network connection and try again."
            
        case .authenticationFailed:
            return "Please verify your login credentials."
            
        case .invalidURL:
            return "Please check the URL format and try again."
            
        case .serverError, .invalidResponse:
            return "The server might be experiencing issues. Please try again later."
            
        default:
            return "Please try again or contact support if the problem persists."
        }
    }
    
    var errorUserInfo: [String: Any] {
        var info: [String: Any] = [NSLocalizedDescriptionKey: errorDescription ?? ""]
        
        if let recovery = recoverySuggestion {
            info[NSLocalizedRecoverySuggestionErrorKey] = recovery
        }
        
        switch self {
        case .invalidResponse(let statusCode, let response):
            info["statusCode"] = statusCode
            info["response"] = response
            
        case .decodingError(_, let error), .encodingError(_, let error):
            info["underlyingError"] = error
            
        case .requestFailed(let underlyingError):
            info["underlyingError"] = underlyingError
            
        case .serverError(_, let message):
            if let message = message {
                info["serverMessage"] = message
            }
            
        default:
            break
        }
        
        return info
    }
}

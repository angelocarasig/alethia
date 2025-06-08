//
//  CollectionError.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import Foundation

enum CollectionError: LocalizedError {
    case notFound(Int64?)
    case badName(String?)
    case minimumLengthNotReached(Int)
    case maximumLengthReached(Int)
    
    // need this
    var errorDescription: String? {
        return localizedDescription
    }
    
    var localizedDescription: String {
        switch self {
        case .notFound(let id):
            if let id = id {
                return "The collection with ID \(id) could not be found in your library. It may have been deleted or moved."
            } else {
                return "The requested collection could not be found in your library."
            }
        case .badName(let name):
            if let name = name {
                return "The collection name '\(name)' is reserved and cannot be used."
            } else {
                return "The collection name provided is invalid."
            }
        case .minimumLengthNotReached(let length):
            let minLength = Constants.Collections.minimumCollectionNameLength
            let characterWord = minLength == 1 ? "character" : "characters"
            return "The collection name must be at least \(minLength) \(characterWord) long but got \(length)."
        case .maximumLengthReached(let length):
            let maxLength = Constants.Collections.maximumCollectionNameLength
            let characterWord = maxLength == 1 ? "character" : "characters"
            return "The collection name cannot exceed \(maxLength) \(characterWord) but got \(length)."
        }
    }
}

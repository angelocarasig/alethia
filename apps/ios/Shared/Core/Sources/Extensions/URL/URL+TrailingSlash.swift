//
//  URL+TrailingSlash.swift
//  Core
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation

public extension URL {
    enum TrailingSlashAction {
        case add
        case remove
    }
    
    /// Modifies the URL's trailing slash based on the specified action
    /// - Parameter action: Whether to add or remove the trailing slash
    /// - Returns: A new URL with the trailing slash modified, or the same URL if no change needed
    func trailingSlash(_ action: TrailingSlashAction) -> URL {
        let hasTrailingSlash = absoluteString.hasSuffix("/")
        
        switch action {
        case .add:
            // if already has trailing slash, return as is
            guard !hasTrailingSlash else { return self }
            return URL(string: absoluteString + "/") ?? self
            
        case .remove:
            // if no trailing slash, return as is
            guard hasTrailingSlash else { return self }
            let cleanedString = String(absoluteString.dropLast())
            return URL(string: cleanedString) ?? self
        }
    }
}

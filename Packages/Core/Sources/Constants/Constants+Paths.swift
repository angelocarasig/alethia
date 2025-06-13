//
//  Constants+Paths.swift
//  Core
//
//  Created by Angelo Carasig on 13/6/2025.
//

import Foundation

public extension Core.Constants {
    struct Paths {
        static let databaseFilePath = getPath(for: "Database")
            .appendingPathComponent("alethia.db")
            .path
        
        public static let downloadsPath = getPath(for: "Downloads")
        
        private static func getPath(for directory: String) -> URL {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Core.Constants.App.identifier
            ) else {
                fatalError("App Group '\(Core.Constants.App.identifier)' not configured.")
            }
            
            let directoryURL = containerURL.appendingPathComponent(directory, isDirectory: true)
            
            do {
                try FileManager.default.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true
                )
                return directoryURL
            } catch {
                fatalError("Failed to create directory at \(directoryURL): \(error)")
            }
        }
    }
}

//
//  Constants+Paths.swift
//  Core
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation

public extension Constants {
    enum Paths {
        public static var database: URL {
            directory("Database").appendingPathComponent("alethia.db")
        }
        
        public static var downloads: URL {
            directory("Downloads")
        }
        
        public static var local: URL {
            directory("Local")
        }
        
        public static func host(_ hostId: String) -> URL {
            local.appendingPathComponent("host-\(hostId)", isDirectory: true)
        }
        
        private static let containerURL: URL = {
            guard let url = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: Core.Constants.App.identifier
            ) else {
                fatalError("App Group '\(Core.Constants.App.identifier)' not configured.")
            }
            return url
        }()
        
        private static func directory(_ name: String) -> URL {
            let url = containerURL.appendingPathComponent(name, isDirectory: true)
            try? FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
            return url
        }
    }
}

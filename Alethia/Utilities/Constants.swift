//
//  Constants.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

struct Constants {}

// MARK: Views
extension Constants {
    struct Padding {
        static let minimal: CGFloat = 4 // Ideally minimum paddingvalue: For any small gaps
        static let regular: CGFloat = 8
        static let screen: CGFloat = 16 // idk some random standard padding value usually used for main screen layout
    }
    
    // Use in gaps for stacks/grids
    struct Spacing {
        static let minimal: CGFloat = 4
        static let regular: CGFloat = 8
        static let large: CGFloat = 12
        static let toolbar: CGFloat = 16 // Toolbar spacing
    }
    
    struct Corner {
        struct Radius {
            static let checkbox: CGFloat = 4
            static let card: CGFloat = 6
            static let regular: CGFloat = 8
            static let button: CGFloat = 12
            static let panel: CGFloat = 20
        }
    }
    
    struct Offset {
        static let badge: CGSize = .init(width: 0, height: -12)
    }
    
    struct Icon {
        struct Size {
            static let regular: CGFloat = 40
            
            static let large: CGFloat = 75
        }
    }
}

extension Constants {
    struct App {
        static let groupIdentifier: String = "group.alethia.app"
    }
}

// MARK: Database Constants
extension Constants {
    struct Database {
        static let Label: String = Constants.App.groupIdentifier
        static let FilePath: String = Constants.Paths.DatabaseFilePath
    }
}

// MARK: Filesystem Paths
extension Constants {
    struct Paths {
        static let DatabaseFilePath: String = {
            let fileManager = FileManager.default
            
            // Always use App Group container
            guard let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: Constants.App.groupIdentifier
            ) else {
                fatalError("App Group '\(Constants.App.groupIdentifier)' not configured. Please add App Groups capability.")
            }
            
            do {
                let dbFolderURL = containerURL
                    .appendingPathComponent("Database", isDirectory: true)
                
                try fileManager.createDirectory(
                    at: dbFolderURL,
                    withIntermediateDirectories: true
                )
                
                return dbFolderURL.appendingPathComponent("alethia.db").path
            } catch {
                fatalError(FilesystemError.fileNotFound("Could not create database file path").localizedDescription)
            }
        }()
        
        static let DownloadsPath: URL = {
            let fileManager = FileManager.default
            guard let containerURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: "group.alethia.app"
            ) else {
                fatalError("App Group '\(Constants.App.groupIdentifier)' not configured.")
            }
            
            do {
                let downloadsFolderURL = containerURL
                    .appendingPathComponent("Downloads", isDirectory: true)
                
                try fileManager.createDirectory(
                    at: downloadsFolderURL,
                    withIntermediateDirectories: true
                )
                
                return downloadsFolderURL
            } catch {
                fatalError(FilesystemError.fileNotFound("Could not create database file path").localizedDescription)
            }
        }()
    }
}

extension Constants {
    struct Collections {
        static let bannedCollectionNames: [String] = [
            "default",
            "new"
        ]
        
        static let minimumCollectionNameLength: Int = 3
        static let maximumCollectionNameLength: Int = 20
    }
}

extension Constants {
    struct Reader {
        static let minimumPageCountForInfinite: Int = 3
    }
}

extension Constants {
    struct Queue {
        static let ConcurrentOperationsCount: Int = 5
    }
}

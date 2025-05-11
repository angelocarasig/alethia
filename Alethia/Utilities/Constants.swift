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
            static let card: CGFloat = 6
            static let regular: CGFloat = 8
            static let button: CGFloat = 12
            static let panel: CGFloat = 20
        }
    }
    
    struct Offset {
        static let badge: CGSize = .init(width: 4, height: -12)
    }
    
    struct Icon {
        struct Size {
            static let regular: CGFloat = 40
            static let large: CGFloat = 75
        }
    }
}

// MARK: Database Constants
extension Constants {
    struct Database {
        static let Label: String = "com.alethia.database"
        static let FilePath: String = Constants.Paths.DatabaseFilePath
    }
}

// MARK: Filesystem Paths
extension Constants {
    struct Paths {
        static let DatabaseFilePath: String = {
            let fileManager = FileManager.default
            do {
                let dbFolderURL = try fileManager.url(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: true
                ).appendingPathComponent("Database", isDirectory: true)
                
                try fileManager.createDirectory(at: dbFolderURL, withIntermediateDirectories: true)
                
                return dbFolderURL.appendingPathComponent("alethia.db").path
            } catch {
                fatalError(FilesystemError.fileNotFound("Could not create database file path").localizedDescription)
            }
        }()
    }
}

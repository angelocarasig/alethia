//
//  FilesystemError.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Foundation

enum FilesystemError: LocalizedError {
    case fileNotFound(String)
    case fileAlreadyExists(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
            case .fileAlreadyExists(let path):
            return "File already exists: \(path)"
        }
    }
}

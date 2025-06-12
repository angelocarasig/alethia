//
//  DownloadError.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

enum DownloadError: LocalizedError {
    case noWritePermission
    case insufficientStorage
    case invalidUrl(String)
    case downloadFailed
    case archiveCreationFailed
    case backgroundTimeExpired
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noWritePermission:
            return "Unable to save downloads. Please check app permissions."
        case .insufficientStorage:
            return "Not enough storage space to download this chapter."
        case .invalidUrl(let url):
            return "Invalid URL for download: \(url)"
        case .downloadFailed:
            return "Download failed."
        case .archiveCreationFailed:
            return "Failed to create archive for chapter."
        case .backgroundTimeExpired:
            return "Download was moved to background but time expired."
        case .unknown(let error):
            return "Download failed: \(error.localizedDescription)"
        }
    }
}

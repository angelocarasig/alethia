//
//  ApplicationError.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation

enum ApplicationError: LocalizedError {
    case operationCancelled
    case internalError
    case urlBuildingFailed(String)
    case batchDeletionError(successCount: Int, failures: [(chapter: Chapter, error: Error)])
    
    var errorDescription: String? {
        switch self {
        case .operationCancelled:
            return "The given operation was cancelled."
        case .internalError:
            return "An internal error occurred."
        case .urlBuildingFailed(let reason):
            return "Tried to build URL but failed: \(reason)"
        case .batchDeletionError(let successCount, let failures):
            let failureCount = failures.count
            if successCount == 0 {
                return "Failed to delete all \(failureCount) chapter downloads."
            } else {
                return "Deleted \(successCount) chapters but failed to delete \(failureCount) chapters."
            }
        }
    }
}

// MARK: - For batch deletion in chapters
extension ApplicationError {
    var failureReasons: [String]? {
        switch self {
        case .batchDeletionError(_, let failures):
            return failures.map { failure in
                "Chapter \(failure.chapter.number.toString()): \(failure.error.localizedDescription)"
            }
        default:
            return nil
        }
    }
}

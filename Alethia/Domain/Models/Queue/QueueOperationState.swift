//
//  QueueOperationState.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation

/// state of current queue operation
enum QueueOperationState: Equatable {
    case pending
    case ongoing(Double) // where double is progress -> 0.0 to 1.0
    case completed
    case cancelled
    case failed(Error)
    
    static func == (lhs: QueueOperationState, rhs: QueueOperationState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending),
            (.completed, .completed),
            (.cancelled, .cancelled):
            return true
        case let (.ongoing(p1), .ongoing(p2)):
            return p1 == p2
        case let (.failed(e1), .failed(e2)):
            return (e1 as NSError) == (e2 as NSError)
        default:
            return false
        }
    }
    
    var isFinished: Bool {
        switch self {
        case .completed, .cancelled, .failed:
            return true
        case .pending, .ongoing:
            return false
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .ongoing:
            return true
        case .completed, .cancelled, .failed:
            return false
        }
    }
}

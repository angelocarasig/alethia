//
//  QueuePriority.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

struct QueuePriority: OptionSet, Comparable {
    let rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// User-initiated urgent actions (value: 1)
    static let urgent = QueuePriority(rawValue: 1 << 0)    // 1
    
    /// Default priority (value: 2)
    static let normal = QueuePriority(rawValue: 1 << 1)    // 2
    
    /// Background operations (value: 4)
    static let low = QueuePriority(rawValue: 1 << 2)       // 4
    
    /// Maintenance operations (value: 8)
    static let background = QueuePriority(rawValue: 1 << 3) // 8
    
    // MARK: - Comparable Implementation (lower value = higher priority)
    
    static func < (lhs: QueuePriority, rhs: QueuePriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Convenience Extensions

extension QueuePriority {
    var description: String {
        switch self {
        case .urgent: return "Urgent"
        case .normal: return "Normal"
        case .low: return "Low"
        case .background: return "Background"
        default: return "Custom(\(rawValue))"
        }
    }
    
    /// Get the highest priority from a set
    static func highest(from priorities: [QueuePriority]) -> QueuePriority? {
        return priorities.min() // Lowest value = highest priority
    }
}

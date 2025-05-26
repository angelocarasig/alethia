//
//  QueueJob.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation

struct QueueJob: Identifiable {
    let id = UUID()
    
    let action: QueueAction
    let priority: QueuePriority
    let date: Date
}

struct QueueJobProgress: Identifiable {
    var id: UUID { jobId }
    
    let jobId: UUID
    var completed: Int
    var total: Int
    var status: Status
    var error: Error?
    var startedAt: Date?
    var completedAt: Date?
    
    enum Status {
        case pending, running, completed, failed, cancelled
    }
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

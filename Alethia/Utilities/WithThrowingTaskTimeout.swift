//
//  WithThrowingTaskTimeout.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Foundation

// Perform a a task with a timeout
func withThrowingTimeout<T>(seconds: UInt64, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            throw CancellationError()
        }
        group.addTask {
            try await operation()
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

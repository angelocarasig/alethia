//
//  RequestThrottler.swift
//  Data
//
//  Created by Angelo Carasig on 19/10/2025.
//

import Foundation

/// actor-based request throttler that limits concurrent requests and staggers them with delays
/// prevents overwhelming backend services with too many simultaneous requests
internal actor RequestThrottler {
    private let maxConcurrent: Int
    private let staggerDelay: Duration
    
    private var activeCount: Int = 0
    private var waitingTasks: [CheckedContinuation<Void, Never>] = []
    
    /// shared instance with sensible defaults
    internal static let shared = RequestThrottler(
        maxConcurrent: 3,
        staggerDelay: .milliseconds(500)
    )
    
    init(maxConcurrent: Int, staggerDelay: Duration) {
        self.maxConcurrent = maxConcurrent
        self.staggerDelay = staggerDelay
    }
    
    /// executes a request with throttling
    /// requests wait in a queue if concurrent limit is reached
    /// each request is staggered by the configured delay
    internal func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        // wait for available slot
        await waitForSlot()
        
        // stagger the request
        try await Task.sleep(for: staggerDelay)
        
        // execute the operation
        defer { releaseSlot() }
        
        do {
            return try await operation()
        } catch {
            throw error
        }
    }
    
    private func waitForSlot() async {
        // if under limit, proceed immediately
        guard activeCount >= maxConcurrent else {
            activeCount += 1
            return
        }
        
        // otherwise, wait in queue
        await withCheckedContinuation { continuation in
            waitingTasks.append(continuation)
        }
        
        activeCount += 1
    }
    
    private func releaseSlot() {
        activeCount -= 1
        
        // resume next waiting task if any
        if !waitingTasks.isEmpty {
            let next = waitingTasks.removeFirst()
            next.resume()
        }
    }
}

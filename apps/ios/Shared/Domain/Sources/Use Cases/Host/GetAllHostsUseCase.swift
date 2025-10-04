//
//  GetAllHostsUseCase.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

/// Use case for observing all saved hosts from the repository
/// Provides real-time updates when hosts are added, modified, or deleted
public protocol GetAllHostsUseCase: Sendable {
    /// Returns an async stream that emits the current list of hosts whenever the database changes
    /// - Returns: AsyncStream of Host arrays that updates on any host/source changes
    func execute() -> AsyncStream<[Host]>
}

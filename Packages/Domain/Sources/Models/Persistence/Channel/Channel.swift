//
//  Channel.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Persistence {
    /// represents the relationship between an origin and scanlator with priority ordering
    ///
    /// - channels define which scanlator groups provide chapters for a specific origin
    /// - priority determining which scanlator's chapters are preferred when multiple groups have translated the same chapter.
    /// - acts as a many-to-many join table with additional business logic for scanlator preference.
    struct Channel: Codable, Sendable {
        // MARK: - Properties
        
        /// joiner to associated origin id
        public var originId: Int64
        
        /// joiner to associated scanlator id
        public var scanlatorId: Int64
        
        /// priority-based algorithm to determine how the unified chapter list
        /// is returned where priority ∈ ℤ, 0 ≤ priority < ∞
        ///
        /// lower values have higher precedence (0 = highest priority).
        public var priority: Int = -1
        
        public init(
            originId: Int64,
            scanlatorId: Int64,
            priority: Int
        ) {
            self.originId = originId
            self.scanlatorId = scanlatorId
            self.priority = priority
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case originId
            case scanlatorId
            case priority
        }
    }
}

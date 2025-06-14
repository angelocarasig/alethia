//
//  Version.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

public extension Domain.Models.Database {
    /// Semantic version representable.
    ///
    /// Version control for the database and used for naming conventions in migrations
    struct Version: Comparable {
        let major: Int
        let minor: Int
        let patch: Int
        
        public var description: String {
            "v\(major).\(minor).\(patch)"
        }
        
        public init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }
        
        public static func < (lhs: Version, rhs: Version) -> Bool {
            if lhs.major != rhs.major { return lhs.major < rhs.major }
            if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
            return lhs.patch < rhs.patch
        }
        
        public func createMigrationName(description: String) -> String {
            return "\(self.description) \(description)".replacingOccurrences(of: " ", with: "_")
        }
    }
}

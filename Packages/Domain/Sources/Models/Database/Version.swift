//
//  Version.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

/// Semantic version representable.
///
/// Version control for the database and used for naming conventions in migrations
internal struct Version: Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    
    init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
    
    var description: String {
        "v\(major).\(minor).\(patch)"
    }
    
    func createMigrationName(description: String) -> String {
        return "\(self.description) \(description)".replacingOccurrences(of: " ", with: "_")
    }
}

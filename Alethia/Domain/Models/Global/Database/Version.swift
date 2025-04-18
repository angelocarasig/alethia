//
//  Version.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation

struct Version: Comparable, CustomStringConvertible {
    let major: Int
    let minor: Int
    let patch: Int
    
    init(_ major: Int, _ minor: Int = 0, _ patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
    
    // Compare versions (e.g., v1.2.3 < v2.0.0)
    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
    
    // Convert to/from database representation (e.g., "1.0.2")
    var description: String { "v\(major).\(minor).\(patch)" }
    
    init?(string: String) {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        self.init(components[0], components[1], components[2])
    }
}

//
//  URL+FirstOrDefault.swift
//  Core
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Foundation

public extension Array where Element == URL {
    var firstOrDefault: URL {
        first ?? URL(string: "")!
    }
}

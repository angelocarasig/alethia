//
//  Date+TimeAgo.swift
//  Core
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Foundation

public extension Date {
    func timeAgo() -> String {
        // 1970-01-01 unix timestamp
        guard timeIntervalSince1970 >= -2208988800 else { return "Never" }
                
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

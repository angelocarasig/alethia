//
//  Date+TimeAgo.swift
//  Core
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Foundation

public extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

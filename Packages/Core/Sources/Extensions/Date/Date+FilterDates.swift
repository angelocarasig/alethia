//
//  Date+FilterDates.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

public extension Date {
    /// Returns the start of the last decade (e.g., Jan 1, 2020 if current year is 2025)
    static var lastDecade: Date {
        let currentYear = Calendar.current.component(.year, from: Date())
        let lastDecadeYear = (currentYear / 10) * 10
        return Calendar.current
            .date(from: DateComponents(year: lastDecadeYear, month: 1, day: 1))
        ?? .distantPast
    }
    
    /// Returns the start of the next decade (e.g., Jan 1, 2030 if current year is 2025)
    static var nextDecade: Date {
        let currentYear = Calendar.current.component(.year, from: Date())
        let nextDecadeYear = ((currentYear / 10) + 1) * 10
        return Calendar.current
            .date(from: DateComponents(year: nextDecadeYear, month: 1, day: 1))
        ?? .distantFuture
    }
    
    /// Returns the start of the previous year (e.g., Jan 1, 2024 if current year is 2025)
    static var lastYear: Date {
        let currentYear = Calendar.current.component(.year, from: Date())
        let previousYear = currentYear - 1
        return Calendar.current
            .date(from: DateComponents(year: previousYear, month: 1, day: 1))
        ?? .distantPast
    }
    
    /// Returns the start of the next year (e.g., Jan 1, 2026 if current year is 2025)
    static var nextYear: Date {
        let currentYear = Calendar.current.component(.year, from: Date())
        let followingYear = currentYear + 1
        return Calendar.current
            .date(from: DateComponents(year: followingYear, month: 1, day: 1))
        ?? .distantFuture
    }
}

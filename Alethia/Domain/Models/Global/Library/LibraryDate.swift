//
//  LibraryDate.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

enum LibraryDate: Equatable {
    case none
    case before(date: Date)                 // Default should be last decade
    case after(date: Date)                  // Default should be next decade
    case between(start: Date, end: Date)    // Default should be between last/next year
    
    static func before(_ date: Date? = nil) -> LibraryDate {
        return .before(date: date ?? .lastDecade)
    }
    
    static func after(_ date: Date? = nil) -> LibraryDate {
        return .after(date: date ?? .nextDecade)
    }
    
    static func between(_ start: Date? = nil, _ end: Date? = nil) -> LibraryDate {
        return .between(start: start ?? .lastYear, end: end ?? .nextYear)
    }
}

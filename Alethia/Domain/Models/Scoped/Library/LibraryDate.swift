//
//  LibraryDate.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import Foundation

enum LibraryDate: Equatable, CaseIterable, Hashable {
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
    
    static var allCases: [LibraryDate] {
        return [
            .none,
            .before(),
            .after(),
            .between()
        ]
    }
    
    var displayText: String {
        switch self {
        case .none:
            return "None"
            
        case .before:
            return "Before"
            
        case .after:
            return "After"
            
        case .between:
            return "Between"
        }
    }
    
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

extension LibraryDate: CustomStringConvertible {
    var description: String { displayText }
}

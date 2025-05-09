//
//  Lock.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Foundation

/// This should be used for one-time boolean-type variables that won't be 'unlocked' again ideally
/// While it can be used in replace of a regular bool it will eventually get confusing
enum Lock: Equatable, ExpressibleByBooleanLiteral {
    case locked
    case unlocked

    init(booleanLiteral value: Bool) {
        self = value ? .locked : .unlocked
    }

    var boolValue: Bool {
        self == .locked
    }
}

extension Lock: @unchecked Sendable {} // for concurrency

extension Lock {
    static prefix func !(lock: Lock) -> Bool {
        !lock.boolValue
    }
}

extension Lock: CustomDebugStringConvertible {
    var debugDescription: String {
        self == .locked ? "🔒 locked" : "🔓 unlocked"
    }
}


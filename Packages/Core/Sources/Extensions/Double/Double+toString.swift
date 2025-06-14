//
//  Double+toString.swift
//  Core
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

public extension Double {
    func toString() -> String {
        return truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}

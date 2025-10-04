//
//  URL+SmartPath.swift
//  Core
//
//  Created by Angelo Carasig on 2/7/2025.
//

import Foundation

public extension URL {
    init?(smartPath: String) {
        if smartPath.hasPrefix("file://") {
            let path = String(smartPath.dropFirst(7))
            self.init(fileURLWithPath: path)
        }
        
        else if smartPath.hasPrefix("/") || smartPath.hasPrefix("~") {
            self.init(fileURLWithPath: smartPath)
        }
        
        else {
            self.init(string: smartPath)
        }
    }
}

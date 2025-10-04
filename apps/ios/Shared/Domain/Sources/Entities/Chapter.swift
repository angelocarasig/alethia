//
//  Chapter.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Chapter {
    public let id: Int64
    
    public let slug: String
    
    public let title: String
    
    public let number: Double
    
    public let date: Date
    
    public let scanlator: String
    
    public let language: LanguageCode
    
    public let url: String
    
    /// refers to its parent source's icon
    public let icon: URL?
    
    public let progress: Double
    
    public var finished: Bool {
        progress >= 1
    }
}

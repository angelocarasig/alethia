//
//  ReaderConfiguration.swift
//  Reader
//
//  Created by Angelo Carasig on 21/10/2025.
//

import UIKit

/// reading mode for the reader
public enum ReadingMode: Sendable, Equatable {
    case infinite
    case vertical
    case leftToRight
    case rightToLeft
}

/// configuration options for the reader
public struct ReaderConfiguration: Sendable, Equatable {
    
    /// background color of the reader
    public let backgroundColor: UIColor
    
    /// whether to show the scroll indicator
    public let showsScrollIndicator: Bool
    
    /// distance from edge in points to trigger chapter loading
    public let loadThreshold: CGFloat
    
    /// reading mode
    public let readingMode: ReadingMode
    
    /// default configuration
    public static let `default` = ReaderConfiguration(
        backgroundColor: .black,
        showsScrollIndicator: false,
        loadThreshold: 500,
        readingMode: .infinite
    )
    
    public init(
        backgroundColor: UIColor = .black,
        showsScrollIndicator: Bool = false,
        loadThreshold: CGFloat = 500,
        readingMode: ReadingMode = .infinite
    ) {
        self.backgroundColor = backgroundColor
        self.showsScrollIndicator = showsScrollIndicator
        self.loadThreshold = loadThreshold
        self.readingMode = readingMode
    }
    
    public static func == (lhs: ReaderConfiguration, rhs: ReaderConfiguration) -> Bool {
        return lhs.backgroundColor == rhs.backgroundColor &&
               lhs.showsScrollIndicator == rhs.showsScrollIndicator &&
               lhs.loadThreshold == rhs.loadThreshold &&
               lhs.readingMode == rhs.readingMode
    }
}

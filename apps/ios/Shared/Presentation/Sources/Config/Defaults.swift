//
//  Defaults.swift
//  Presentation
//
//  Created by Angelo Carasig on 16/6/2025.
//

import Foundation
import Core

@MainActor @propertyWrapper
internal struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let store: UserDefaults
    
    init(key: String, defaultValue: T, suite: String? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.store = UserDefaults(suiteName: suite) ?? .standard
    }
    
    var wrappedValue: T {
        get { store.object(forKey: key) as? T ?? defaultValue }
        set { store.set(newValue, forKey: key) }
    }
}

extension UserDefault where T: ExpressibleByNilLiteral {
    init(key: String, suite: String? = nil) {
        self.init(key: key, defaultValue: nil, suite: suite)
    }
}

// MARK: - Global

internal struct Defaults {
    private static let suite = Core.Constants.App.identifier
    
    enum Keys {
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let gridColumns = "gridColumns"
        static let pillarboxSize = "pillarboxSize"
        
        enum Library {
            static let sortType = "library.sortType"
            static let sortDirection = "library.sortDirection"
        }
    }
    
    @UserDefault(key: Keys.hapticFeedbackEnabled, defaultValue: true, suite: suite)
    static var hapticFeedbackEnabled: Bool
    
    @UserDefault(key: Keys.gridColumns, defaultValue: 3, suite: suite)
    static var gridColumns: Int
    
    @UserDefault(key: Keys.pillarboxSize, defaultValue: 0.0, suite: suite)
    static var pillarboxSize: Double
}

// MARK: - Library

extension Defaults {
    enum Library {
        @UserDefault(key: Keys.Library.sortType, defaultValue: "name", suite: suite)
        static var sortType: String
        
        @UserDefault(key: Keys.Library.sortDirection, defaultValue: "ascending", suite: suite)
        static var sortDirection: String
    }
}

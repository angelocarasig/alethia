//
//  IOSViewModelResolver.swift
//  Composition
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Presentation
import Data
import Domain
import Core

/// iOS-specific implementation of the ViewModelResolver
public final class IOSViewModelResolver: ViewModelResolver {
    private let database: DatabaseConfiguration
    
    public init() {
        // initialize database (this will run migrations)
        self.database = DatabaseConfiguration.shared
        print("✅ Database initialized successfully")
    }
}

//
//  Resolver.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI

/// Protocol defining the contract for resolving ViewModels
/// Each app target implements this to provide platform-specific ViewModels
public protocol ViewModelResolver {
    // add viewmodel resolution methods here as we create views
    // example: func resolveLibraryViewModel() -> any LibraryViewModel
}

/// Global resolver instance used by views to get their ViewModels
public final class Resolver: @unchecked Sendable {
    private static let shared = Resolver()
    private var resolver: ViewModelResolver?
    
    private init() {}
    
    public static var current: ViewModelResolver {
        guard let resolver = shared.resolver else {
            fatalError("Resolver not set up. Call Resolver.setup() at app launch.")
        }
        return resolver
    }
    
    /// Must be called once at app launch to set up the resolver
    public static func setup(_ resolver: ViewModelResolver) {
        shared.resolver = resolver
    }
}

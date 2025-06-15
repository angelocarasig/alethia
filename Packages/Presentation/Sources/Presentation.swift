//
//  Presentation.swift
//  Presentation
//
//  Created by Angelo Carasig on 15/6/2025.
//

import SwiftUI
import Domain
import Composition

public struct Presentation {
    // public factory methods for creating views
    private init() {}
}

@MainActor
public extension Presentation {
    static func makeLibraryScreen() -> some View {
        return LibraryScreen(vm: Composition.Factory.ViewModel.makeLibraryViewModel())
    }
    
    static func makeDetailsScreen(entry: Domain.Models.Virtual.Entry) -> some View {
        Text("Details screen coming soon: \(entry.title)")
    }
}

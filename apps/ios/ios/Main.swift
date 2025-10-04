//
//  Main.swift
//  Alethia
//
//  Created by Angelo Carasig on 27/9/2025.
//

import SwiftUI
import Presentation
import Composition

@main
struct Main: App {
    init() {
        // set up the resolver with ios-specific implementation
        Resolver.setup(IOSViewModelResolver())
    }
    
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}

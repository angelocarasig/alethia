//
//  AlethiaApp.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import SwiftUI

@main
struct AlethiaApp: App {
    @State var database: DatabaseProvider = DatabaseProvider.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

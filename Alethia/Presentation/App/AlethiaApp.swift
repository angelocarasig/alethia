//
//  AlethiaApp.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import SwiftUI

@main
struct AlethiaApp: App {
    var database: DatabaseProvider = DatabaseProvider.shared
    var kingfisher: KingfisherProvider = KingfisherProvider.shared
    
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeScreen()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                LibraryScreen()
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("Library")
                    }
                
                SourcesScreen()
                    .tabItem {
                        Image(systemName: "plus.square.dashed")
                        Text("Sources")
                    }
                
                HistoryScreen()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                
                SettingsScreen()
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
            }
        }
    }
}

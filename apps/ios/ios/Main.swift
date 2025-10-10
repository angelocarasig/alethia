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
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                Text("TODO")
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                Text("TODO")
                    .tabItem {
                        Image(systemName: "books.vertical.fill")
                        Text("Library")
                    }
                
                Text("TODO")
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                
                SourcesScreen()
                    .tabItem {
                        Image(systemName: "plus.square.dashed")
                        Text("Sources")
                    }
                
                Text("TODO")
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
            }
        }
    }
    
    func setupApp() {
        ImageCacheConfiguration.shared.configure()
    }
}

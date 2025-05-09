//
//  SettingsScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: EmptyView()) {
                        Image(systemName: "gear")
                            .padding(4)
                            .background(Color.secondary)
                            .cornerRadius(8)
                        
                        Text("General")
                    }
                    
                    NavigationLink(destination: SettingsSourcesView()) {
                        Image(systemName: "leaf.arrow.circlepath")
                            .padding(4)
                            .background(Color.blue)
                            .cornerRadius(8)
                        
                        Text("Sources")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


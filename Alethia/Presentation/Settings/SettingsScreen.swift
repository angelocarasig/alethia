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
                            .padding(Constants.Padding.minimal)
                            .background(Color.secondary)
                            .cornerRadius(Constants.Corner.Radius.regular)
                        
                        Text("General")
                    }
                    
                    NavigationLink(destination: SettingsSourcesView()) {
                        Image(systemName: "leaf.arrow.circlepath")
                            .padding(Constants.Padding.minimal)
                            .background(Color.blue)
                            .cornerRadius(Constants.Corner.Radius.regular)
                        
                        Text("Sources")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


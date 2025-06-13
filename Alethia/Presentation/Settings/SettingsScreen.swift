//
//  SettingsScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Core
import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: EmptyView()) {
                        Image(systemName: "gear")
                            .padding(.Padding.minimal)
                            .background(Color.secondary)
                            .cornerRadius(.Corner.regular)
                        
                        Text("General")
                    }
                    
                    NavigationLink(destination: SettingsSourcesView()) {
                        Image(systemName: "leaf.arrow.circlepath")
                            .padding(.Padding.minimal)
                            .background(Color.blue)
                            .cornerRadius(.Corner.regular)
                        
                        Text("Sources")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


//
//  SourcesScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI

public struct SourcesScreen: View {
    @State private var showingAddSourceSheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack {
                Text("HI")
            }
            .navigationTitle("Sources")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSourceSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSourceSheet) {
                AddHostView()
            }
        }
    }
}

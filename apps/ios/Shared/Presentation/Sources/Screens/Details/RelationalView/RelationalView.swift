//
//  RelationalView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct RelationalView: View {
    @Environment(\.dimensions) private var dimensions
    
    let manga: Manga
    
    var body: some View {
        VStack(spacing: dimensions.spacing.regular) {
            TrackingView(title: manga.title, authors: manga.authors)
            
            Divider()
            
            SourcesView(origins: manga.origins)
            
            Divider()
            
            CollectionsView()
        }
    }
}

struct CollectionsView: View {
    @State var isPresented: Bool = false
    
    var body: some View {
        Button("Present") {
            isPresented.toggle()
        }
        .sheet(isPresented: $isPresented) {
            Text("Hello, World!")
        }
    }
}

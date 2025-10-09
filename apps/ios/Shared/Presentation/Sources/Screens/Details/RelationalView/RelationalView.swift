//
//  RelationalView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct RelationalView: View {
    
    let manga: Manga
    
    var body: some View {
        VStack(spacing: 0) {
            TrackingView(title: manga.title, authors: manga.authors)
            
            Divider()
            
            SourcesView()
            
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

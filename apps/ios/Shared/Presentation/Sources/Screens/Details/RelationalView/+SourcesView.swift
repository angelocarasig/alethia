//
//  SourcesView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct SourcesView: View {
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

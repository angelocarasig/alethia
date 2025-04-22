//
//  SourceCardView.swift
//  Alethia
//
//  Created by Angelo Carasig on 6/2/2025.
//

import SwiftUI

struct SourceCardView: View {
    let namespace: Namespace.ID
    
    let entry: Entry

    let id = UUID().uuidString
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry)
                .navigationTransition(.zoom(sourceID: "image-\(id)", in: namespace))
        } label: {
            EntryView(item: entry)
                .matchedTransitionSource(id: "image-\(id)", in: namespace)
        }
    }
}

//
//  File.swift
//  Presentation
//
//  Created by Angelo Carasig on 9/10/2025.
//

import SwiftUI
import Domain

struct SourceCard: View {
    let id: String
    let entry: Entry
    let namespace: Namespace.ID
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry)
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } label: {
            EntryCard(entry: entry, lineLimit: 2)
                .frame(width: 125)
                .id(id)
                .matchedTransitionSource(id: id, in: namespace)
        }
    }
}

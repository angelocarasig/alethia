//
//  SourceCardView.swift
//  Alethia
//
//  Created by Angelo Carasig on 6/2/2025.
//

import SwiftUI

struct SourceCardView: View {
    let namespace: Namespace.ID
    let source: Source
    let entry: Entry
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry, source: source)
                .navigationTransition(.zoom(sourceID: entry.transitionId, in: namespace))
        } label: {
            EntryView(
                item: entry,
                downsample: true,
                lineLimit: 2
            )
            .matchedTransitionSource(id: entry.transitionId, in: namespace)
        }
        .id("\(entry.id)-\(entry.match)")
    }
}

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
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry)
                .navigationTransition(.zoom(sourceID: entry.transitionId, in: namespace))
        } label: {
            EntryView(item: entry)
                .matchedTransitionSource(id: entry.transitionId, in: namespace)
        }
    }
}

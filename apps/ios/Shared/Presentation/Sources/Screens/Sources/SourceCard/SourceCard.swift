//
//  SourceCard.swift
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
    let width: CGFloat?
    
    init(
        id: String,
        entry: Entry,
        namespace: Namespace.ID,
        width: CGFloat? = 125
    ) {
        self.id = id
        self.entry = entry
        self.namespace = namespace
        self.width = width
    }
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationLink {
            DetailsScreen(entry: entry)
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } label: {
            EntryCard(entry: entry, lineLimit: 2)
                .if(width != nil) {content in
                    content
                        .frame(width: width)
                }
                .overlay {
                    if entry.state != .noMatch {
                        matchOverlay
                    }
                }
                .id(id)
                .matchedTransitionSource(id: id, in: namespace)
        }
    }
    
    @ViewBuilder
    private var matchOverlay: some View {
        ZStack {
            // background tint
            Color.black.opacity(0.5)
                .cornerRadius(dimensions.cornerRadius.card)
            
            // match badge
            Image(systemName: matchStateIcon(for: entry.state))
                .font(.system(size: 18))
                .foregroundColor(matchStateColor(for: entry.state))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(dimensions.padding.regular)
        }
    }
    
    // MARK: - Match State Helpers
    
    private func matchStateIcon(for state: EntryState) -> String {
        switch state {
        case .exactMatch:
            return "checkmark.circle.fill"
        case .crossSourceMatch:
            return "arrow.left.arrow.right.circle.fill"
        case .titleMatchSameSource:
            return "circle.bottomhalf.filled.inverse"
        case .titleMatchSameSourceAmbiguous:
            return "questionmark.circle.fill"
        case .titleMatchDifferentSource:
            return "circle.lefthalf.filled.inverse"
        case .matchVerificationFailed:
            return "exclamationmark.triangle.fill"
        case .noMatch:
            return ""
        }
    }
    
    private func matchStateColor(for state: EntryState) -> Color {
        switch state {
        case .exactMatch:
            return theme.colors.appGreen
        case .crossSourceMatch:
            return theme.colors.appBlue
        case .titleMatchSameSource:
            return theme.colors.appYellow
        case .titleMatchSameSourceAmbiguous:
            return theme.colors.appOrange
        case .titleMatchDifferentSource:
            return theme.colors.appPurple
        case .matchVerificationFailed:
            return theme.colors.appRed
        case .noMatch:
            return .clear
        }
    }
}

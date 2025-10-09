//
//  TrackingView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct TrackingView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let title: String
    let authors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            DetailHeader(title: "Tracking")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: dimensions.spacing.minimal) {
                trackerRow(
                    iconName: "AniList",
                    serviceName: "AniList",
                    lastTracked: "67 mins ago"
                )
                
                trackerRow(
                    iconName: "MyAnimeList",
                    serviceName: "MyAnimeList",
                    lastTracked: "2 hours ago"
                )
                
                trackerRow(
                    iconName: "Kitsu",
                    serviceName: "Kitsu",
                    lastTracked: "1 day ago",
                    disabled: true
                )
            }
        }
    }
    
    @ViewBuilder
    private func trackerRow(
        iconName: String,
        serviceName: String,
        lastTracked: String,
        disabled: Bool = false
    ) -> some View {
        HStack {
            icon(named: iconName)
            info(serviceName: serviceName, lastTracked: lastTracked)
            Spacer()
            refresh
        }
        .padding(.vertical, dimensions.padding.regular)
        .opacity(disabled ? 0.4 : 1.0)
    }
    
    @ViewBuilder
    private func icon(named: String) -> some View {
        Image(named, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(dimensions.icon.chapter)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular))
            .padding(.trailing, dimensions.padding.regular)
    }
    
    @ViewBuilder
    private func info(serviceName: String, lastTracked: String) -> some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
            HStack {
                Text(serviceName)
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(lastTracked)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            Text(title)
                .lineLimit(2)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(authors.joined(separator: ", "))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var refresh: some View {
        Button {
            // no action for now
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.body)
                .foregroundColor(.accentColor)
        }
        .frame(dimensions.icon.pill)
        .padding(.horizontal, dimensions.padding.regular)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            Text("Content Above")
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
            
            TrackingView(
                title: "Solo Leveling",
                authors: ["Chugong", "DUBU (REDICE STUDIO)"]
            )
            .padding(.horizontal)
            
            Text("Content Below")
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
        }
    }
}

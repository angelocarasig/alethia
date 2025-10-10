//
//  HeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI
import Domain
import Kingfisher

struct HeaderView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var showAlternativeTitles: Bool = false
    @State private var showCovers: Bool = false
    
    var cover: URL
    var title: String
    var alternativeTitles: [String]
    var authors: [String]
    var covers: [URL]
    
    var body: some View {
        VStack(alignment: .leading) {
            KFImage(cover)
                .placeholder { theme.colors.tint.shimmer() }
                .resizable()
                .coverCache()
                .framed(maxWidth: 200, maxHeight: 200)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular, style: .continuous))
                .tappable {
                    showCovers = true
                }
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contextMenu { TitleContextMenu() }
                    .tappable {
                        if !alternativeTitles.isEmpty {
                            showAlternativeTitles = true
                        }
                    }
                
                Text(authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showAlternativeTitles) {
            AlternativeTitlesSheet(
                primaryTitle: title,
                alternativeTitles: alternativeTitles
            )
        }
        .sheet(isPresented: $showCovers) {
            CoversSheet(
                title: title,
                primary: cover,
                covers: covers
            )
        }
    }
    
    @ViewBuilder
    private func TitleContextMenu() -> some View {
        Section {
            Button {
                UIPasteboard.general.string = title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc")
            }
            
            Button {
                // TODO: search for this title
            } label: {
                Label("Search Other Sources For This Title", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview {
    HeaderView(
        cover: URL(string: "https://mangadex.org/covers/77bee52c-d2d6-44ad-a33a-1734c1fe696a/cover.jpg")!,
        title: "Dungeon Meshi",
        alternativeTitles: ["ダンジョン飯", "Delicious in Dungeon"],
        authors: ["Kui Ryouko"],
        covers: [
            URL(string: "https://mangadex.org/covers/77bee52c-d2d6-44ad-a33a-1734c1fe696a/cover.jpg")!,
            URL(string: "https://mangadex.org/covers/77bee52c-d2d6-44ad-a33a-1734c1fe696a/cover2.jpg")!
        ]
    )
    .padding()
}

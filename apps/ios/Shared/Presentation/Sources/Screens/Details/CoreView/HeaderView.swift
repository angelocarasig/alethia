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
    
    @State private var showArtwork: Bool = false
    
    var cover: URL
    var title: String
    var authors: [String]
    var manga: Manga?
    
    var body: some View {
        VStack(alignment: .leading) {
            KFImage(cover)
                .placeholder { theme.colors.tint.shimmer() }
                .resizable()
                .framed(maxWidth: 200, maxHeight: 200)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular, style: .continuous))
                .tappable { showArtwork = true }
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showArtwork) {
            ArtworkSheet()
        }
    }
}

//
//  EntryCard.swift
//  Presentation
//
//  Created by Angelo Carasig on 17/6/2025.
//

import SwiftUI
import Kingfisher
import Domain

internal struct EntryCard: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var entry: Entry
    var showTitle: Bool
    var lineLimit: Int
    
    init(
        entry: Entry,
        showTitle: Bool = true,
        lineLimit: Int = 1
    ) {
        self.entry = entry
        
        self.showTitle = showTitle
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                
                KFImage(entry.cover)
                    .placeholder {
                        theme.colors.tint.shimmer()
                    }
                    .coverCache()
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(dimensions.cornerRadius.card)
                    .clipped()
            }
            .aspectRatio(11/16, contentMode: .fit)
            
            if showTitle {
                Text(entry.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(lineLimit, reservesSpace: lineLimit > 1)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .foregroundColor(theme.colors.foreground)
            }
            
            Spacer()
        }
        .padding(.horizontal, dimensions.padding.minimal)
    }
}

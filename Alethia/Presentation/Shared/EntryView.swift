//
//  EntryView.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftUI
import Kingfisher

struct EntryView: View {
    let item: Entry
    let lineLimit: Int
    
    init(
        item: Entry,
        lineLimit: Int? = 1
    ) {
        self.item = item
        self.lineLimit = lineLimit ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                let match = item.match
                
                KFImage(URL(string: item.cover ?? ""))
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: cellWidth * 1.5, height: cellHeight * 1.5)))
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(6)
                    .clipped()
                    .overlay {
                        if match != .none {
                            ZStack(alignment: .topTrailing) {
                                Color.black.opacity(0.5)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(6)
                                
                                if match == .exact {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                        .padding(10)
                                }
                                else if match == .partial {
                                    Image(systemName: "circle.bottomhalf.filled.inverse")
                                        .font(.system(size: 18))
                                        .foregroundColor(.appYellow)
                                        .padding(10)
                                }
                            }
                        }
                    }
            }
            .aspectRatio(11/16, contentMode: .fit)
            
            Text(item.title)
                .font(.system(size: 14))
                .fontWeight(.medium)
                .lineLimit(lineLimit, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .truncationMode(.tail)
                .foregroundStyle(.text)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }
}

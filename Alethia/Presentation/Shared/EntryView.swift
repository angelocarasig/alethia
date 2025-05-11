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
    let downsample: Bool
    let lineLimit: Int
    let showUnread: Bool
    
    init(
        item: Entry,
        downsample: Bool = false,
        lineLimit: Int = 1,
        showUnread: Bool = false
    ) {
        self.item = item
        self.downsample = downsample
        self.lineLimit = lineLimit
        self.showUnread = showUnread
    }
    
    var processors: [any ImageProcessor] {
        var imageProcessors: [any ImageProcessor] = []
        
        if downsample {
            imageProcessors.append(DownsamplingImageProcessor(size: .init(width: 350, height: 400)))
        }
        
        return imageProcessors
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geometry in
                let cellWidth = geometry.size.width
                let cellHeight = cellWidth * 16 / 11
                
                KFImage(URL(string: item.cover ?? ""))
                    .setProcessors(processors)
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .fade(duration: 0.25)
                    .scaledToFill()
                    .frame(width: cellWidth, height: cellHeight)
                    .cornerRadius(Constants.Corner.Radius.card)
                    .clipped()
                    .overlay(MatchOverlay(match: item.match))
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
        .padding(.horizontal, Constants.Padding.minimal)
    }
    
    @ViewBuilder
    private func MatchOverlay(match: EntryMatch) -> some View {
        if match != .none {
            ZStack(alignment: .topTrailing) {
                Color.black.opacity(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(Constants.Corner.Radius.card)
                
                if match == .exact {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .padding(Constants.Padding.regular)
                }
                
                else if match == .partial {
                    Image(systemName: "circle.bottomhalf.filled.inverse")
                        .font(.system(size: 18))
                        .foregroundColor(.appYellow)
                        .padding(Constants.Padding.regular)
                }
            }
        }
    }
}

private struct UnreadBadgeModifier: ViewModifier {
    let unread: Int
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            
            if unread > 0 {
                let unreadAmount = "\(min(unread, 99))\(unread >= 99 ? "+" : "")"
                
                Text(unreadAmount)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
                    .background(.red)
                    .clipShape(.capsule)
                    .offset(y: -12)
            }
        }
    }
}

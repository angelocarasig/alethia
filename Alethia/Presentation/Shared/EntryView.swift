//
//  EntryView.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/11/2024.
//

import SwiftUI
import Kingfisher
import Combine

struct EntryView: View {
    let item: Entry
    let downsample: Bool
    let lineLimit: Int
    let showUnread: Bool
    
    @StateObject private var queueProvider = QueueProvider.shared
    @State private var queueState: EntryQueueState = .idle
    
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
    
    private var shouldShowOverlay: Bool {
        !queueState.isEmpty || item.match != .none
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
                    .overlay(OverlayStack())
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
        .onReceive(queueProvider.entryStatePublisher(entry: item).removeDuplicates()) { newState in
            withAnimation {
                queueState = newState
            }
        }
    }
}

// MARK: - Supporting Views

extension EntryView {
    @ViewBuilder
    private func OverlayStack() -> some View {
        ZStack {
            // Background overlay - shown when any overlay needs to be displayed
            if shouldShowOverlay {
                Color.black.opacity(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(Constants.Corner.Radius.card)
            }
            
            // Individual overlays
            MatchOverlay(match: item.match)
            QueueOverlay(state: queueState)
        }
    }
    
    @ViewBuilder
    private func MatchOverlay(match: EntryMatch) -> some View {
        if match != .none {
            Group {
                if match == .exact {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                }
                else if match == .partial {
                    Image(systemName: "circle.bottomhalf.filled.inverse")
                        .font(.system(size: 18))
                        .foregroundColor(.appYellow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(Constants.Padding.regular)
        }
    }
    
    @ViewBuilder
    private func QueueOverlay(state: EntryQueueState) -> some View {
        if !state.isEmpty {
            HStack(spacing: 4) {
                if state.isDownloading {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .pulse(scale: 1.1)
                }
                
                if state.isUpdatingMetadata {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.blue)
                        .spin()
                }
            }
            .font(.system(size: 24))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(Constants.Padding.regular)
        }
    }
}

#Preview("Regular Entry") {
    EntryView(item: Entry(
        mangaId: 1,
        title: "One Piece",
        cover: "https://example.com/onepiece.jpg",
        inLibrary: true,
        unread: 5
    ))
    .frame(width: 120, height: 200)
    .padding()
}

#Preview("Entry with Match") {
    VStack(spacing: 20) {
        EntryView(item: Entry(
            mangaId: 2,
            title: "Naruto",
            cover: "https://example.com/naruto.jpg",
            inLibrary: true,
            unread: 12,
            match: .exact
        ))
        .frame(width: 120, height: 200)
        
        EntryView(item: Entry(
            mangaId: 3,
            title: "Bleach",
            cover: "https://example.com/bleach.jpg",
            inLibrary: true,
            unread: 3,
            match: .partial
        ))
        .frame(width: 120, height: 200)
    }
    .padding()
}

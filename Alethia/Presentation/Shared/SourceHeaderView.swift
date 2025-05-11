//
//  SourceHeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI
import Kingfisher

// a fancy design of a source - use in source/search results
struct SourceHeaderView: View {
    @State private var currentIndex = 0
    @State private var prefetcher: ImagePrefetcher?
    
    let source: Source
    let images: [String]
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let downsample: CGSize = .init(width: 200, height: 200)
    
    // TODO: Place in use-case
    //    var inLibraryCount: Int {
    //        (try? DatabaseProvider.shared.reader.read { db in
    //            try Origin
    //                .joining(required: Origin.manga.filter(Manga.Columns.inLibrary))
    //                .filter(Origin.Columns.sourceId == source.id)
    //                .fetchCount(db)
    //        }) ?? 0
    //    }
    
    var body: some View {
        ZStack {
            let urlString = images.indices.contains(currentIndex) ? images[currentIndex] : ""
            
            KFImage(URL(string: urlString))
                .setProcessors([
                    DownsamplingImageProcessor(size: downsample),
                    BlurImageProcessor(blurRadius: 10)
                ])
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .fade(duration: 0.25)
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 350)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear,    location: 0.0),
                            .init(color: Color.background.opacity(0.75), location: 0.7),
                            .init(color: Color.background, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                )
                .id(currentIndex)
            
            VStack(spacing: 10) {
                KFImage(URL(fileURLWithPath: source.icon))
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Constants.Icon.Size.large,
                        height: Constants.Icon.Size.large
                    )
                    .clipShape(.circle)
                
                Text(source.name)
                    .lineLimit(1)
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding()
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = (currentIndex + 1) % max(images.count, 1)
            }
        }
        .onChange(of: images) {
            prefetch()
        }
    }
    
    private func prefetch() -> Void {
        let urls: [URL] = images.map { URL(string: $0)! }
        
        prefetcher?.stop()
        prefetcher = ImagePrefetcher(
            urls: urls,
            options: [.waitForCache, .backgroundDecode],
            progressBlock: nil
        )
        
        prefetcher?.start()
    }
}


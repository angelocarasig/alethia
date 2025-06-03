//
//  SourceHeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Kingfisher
import Combine

struct SourceHeaderView: View {
    @State private var currentIndex = 0
    @State private var showNavTitle = false
    @State private var pingStatus: PingStatus = .idle
    @State private var pingTime: String = ""
    @State private var prefetcher: ImagePrefetcher?
    
    let source: Source
    let artworkUrls: [String]  // Changed from featuredEntries to just artwork URLs
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let headerHeight: CGFloat = 450
    
    // Computed properties
    private var currentImage: String {
        artworkUrls.indices.contains(currentIndex) ? artworkUrls[currentIndex] : ""
    }
    
    private var host: Host? {
        try? DatabaseProvider.shared.reader.read { db in
            try Host.fetchOne(db, key: source.hostId)
        }
    }
    
    // Ping Status
    private enum PingStatus {
        case idle
        case loading
        case success(TimeInterval)
        case failed
        
        var color: Color {
            switch self {
            case .idle, .loading:
                return .gray
            case .success:
                return .green
            case .failed:
                return .red
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with parallax effect
            GeometryReader { geometry in
                ZStack {
                    // Carousel background
                    if !artworkUrls.isEmpty {
                        TabView(selection: $currentIndex) {
                            ForEach(artworkUrls.indices, id: \.self) { index in
                                KFImage(URL(string: artworkUrls[index]))
                                    .placeholder { Color.tint.shimmer() }
                                    .resizable()
                                    .fade(duration: 0.5)
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: headerHeight)
                                    .clipped()
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .animation(.easeInOut(duration: 0.8), value: currentIndex)
                    } else {
                        // Fallback gradient
                        LinearGradient(
                            colors: [Color.background, Color.background.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    
                    // Dark overlay gradient
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.background.opacity(0.3), location: 0.0),
                            .init(color: Color.background.opacity(0.7), location: 0.5),
                            .init(color: Color.background.opacity(0.95), location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: headerHeight)
            }
            .frame(height: headerHeight)
            
            // Content overlay
            VStack(spacing: 0) {
                Spacer(minLength: 100)
                
                // Main content
                VStack(spacing: Constants.Spacing.large) {
                    // Source icon
                    KFImage(URL(fileURLWithPath: source.icon))
                        .placeholder {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .shimmer()
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(.circle)
                    
                    // Title
                    Text(source.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Description
                    Text(source.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, Constants.Padding.screen)
                    
                    // Stats row
                    HStack(spacing: 30) {
                        // Ping status
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(pingStatus.color)
                                    .frame(width: 8, height: 8)
                                    .symbolEffect(.pulse, options: .repeating, value: pingStatus.color == .green)
                                
                                Text(pingTimeText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Text("STATUS")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                                .fontWeight(.semibold)
                        }
                        
                        // Divider
                        Rectangle()
                            .foregroundColor(Color.secondary)
                            .frame(width: 1, height: 30)
                        
                        // Maintainer/Host
                        VStack(spacing: 4) {
                            if let host = host {
                                Text("@\(host.author)/\(host.name)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .textCase(.lowercase)
                            } else {
                                Text("@unknown")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.secondary)
                                    .textCase(.lowercase)
                            }
                            
                            Text("MAINTAINER")
                                .font(.caption2)
                                .foregroundColor(Color.secondary)
                                .fontWeight(.semibold)
                        }
                        
                        // Divider
                        Rectangle()
                            .foregroundColor(Color.secondary)
                            .frame(width: 1, height: 30)
                        
                        // Website link
                        Link(destination: URL(string: source.website) ?? URL(string: "https://example.com")!) {
                            VStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                
                                Text("WEBSITE")
                                    .font(.caption2)
                                    .foregroundColor(Color.secondary)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding(.vertical, Constants.Padding.regular)
                    .padding(.horizontal, Constants.Padding.screen)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .background(
                                Capsule()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .padding(.bottom, 30)
            }
        }
        .frame(height: headerHeight)
        .background(Color.background)
        .onReceive(timer) { _ in
            if artworkUrls.count > 1 {
                withAnimation(.spring) {
                    currentIndex = (currentIndex + 1) % artworkUrls.count
                }
            }
        }
        .task {
            await performPing()
            prefetchImages()
        }
    }
    
    // MARK: - Computed Properties
    
    private var pingTimeText: String {
        switch pingStatus {
        case .idle:
            return "Idle"
        case .loading:
            return "Pinging..."
        case .success(let time):
            return String(format: "%.0f ms", time * 1000)
        case .failed:
            return "Offline"
        }
    }
    
    // MARK: - Methods
    
    private func performPing() async {
        guard let host = host else { return }
        
        let pingUrl = URL.appendingPaths(host.baseUrl, source.path, "ping")?.absoluteString ?? ""
        guard let url = URL(string: pingUrl) else { return }
        
        withAnimation {
            pingStatus = .loading
        }
        
        do {
            let ns = NetworkService()
            let result = try await ns.ping(url: url)
            withAnimation {
                pingStatus = .success(result)
            }
        } catch {
            withAnimation {
                pingStatus = .failed
            }
        }
    }
    
    private func prefetchImages() {
        let urls = artworkUrls.compactMap { URL(string: $0) }
        
        prefetcher?.stop()
        prefetcher = ImagePrefetcher(
            urls: urls,
            options: KingfisherProvider.prefetchOptions
        )
        prefetcher?.start()
    }
}

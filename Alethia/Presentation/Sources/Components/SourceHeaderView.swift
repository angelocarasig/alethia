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
    // MARK: - Properties
    
    @State private var currentIndex = 0
    @State private var pingStatus: PingStatus = .idle
    @State private var prefetcher: ImagePrefetcher?
    
    let source: Source
    let artworkUrls: [String]
    
    // MARK: - Constants
    
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    private let headerHeight: CGFloat = 400
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            contentOverlay
        }
        .frame(height: headerHeight)
        .background(Color.background)
        .onReceive(timer) { _ in
            cycleImages()
        }
        .task {
            await performPing()
            prefetchImages()
        }
    }
}

// MARK: - View Components

private extension SourceHeaderView {
    var backgroundLayer: some View {
        GeometryReader { geometry in
            ZStack {
                carouselBackground(geometry: geometry)
                gradientOverlay
            }
            .frame(height: headerHeight)
        }
        .frame(height: headerHeight)
    }
    
    var contentOverlay: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: Constants.Spacing.regular) {
                sourceIcon
                titleSection
                statsRow
            }
            .padding(.bottom, Constants.Padding.screen)
        }
    }
    
    var sourceIcon: some View {
        KFImage(URL(fileURLWithPath: source.icon))
            .placeholder {
                Circle()
                    .fill(Color.tint.opacity(0.1))
                    .shimmer()
            }
            .resizable()
            .scaledToFit()
            .frame(width: 72, height: 72)
            .clipShape(Circle())
    }
    
    var titleSection: some View {
        VStack(spacing: Constants.Spacing.minimal) {
            Text(source.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text(source.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, Constants.Padding.screen)
        }
    }
    
    var statsRow: some View {
        HStack(spacing: 0) {
            statusIndicator
            Divider().frame(height: 32)
            maintainerInfo
            Divider().frame(height: 32)
            websiteLink
        }
        .padding(.vertical, Constants.Padding.regular)
        .padding(.horizontal, Constants.Padding.regular)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Stats Components

private extension SourceHeaderView {
    var statusIndicator: some View {
        HStack(spacing: 8) {
            Group {
                switch pingStatus {
                case .idle:
                    Image(systemName: "circle.dotted")
                        .symbolEffect(.pulse, options: .repeating, value: true)
                case .loading:
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .symbolEffect(.variableColor.iterative, options: .repeating, value: true)
                case .success:
                    Image(systemName: "wifi")
                        .symbolEffect(.pulse.wholeSymbol, options: .repeating, value: true)
                case .failed:
                    Image(systemName: "wifi.slash")
                        .symbolEffect(.bounce.up.wholeSymbol, value: true)
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(pingStatus.color)
            .contentTransition(.symbolEffect(.replace))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(pingStatus.displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text("Status")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var maintainerInfo: some View {
        VStack(spacing: 2) {
            Group {
                if let host = host {
                    Text("@\(host.author)")
                        .font(.caption)
                        .textCase(.lowercase)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                } else {
                    Text("Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("Maintainer")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }
    
    var websiteLink: some View {
        Link(destination: URL(string: source.website) ?? URL(string: "https://www.google.com")!) {
            VStack(spacing: 2) {
                Image(systemName: "safari")
                    .font(.footnote)
                
                Text("Website")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Background Components

private extension SourceHeaderView {
    func carouselBackground(geometry: GeometryProxy) -> some View {
        Group {
            if !artworkUrls.isEmpty {
                TabView(selection: $currentIndex) {
                    ForEach(artworkUrls.indices, id: \.self) { index in
                        KFImage(URL(string: artworkUrls[index]))
                            .placeholder {
                                Rectangle()
                                    .fill(Color.tint.opacity(0.1))
                                    .shimmer()
                            }
                            .resizable()
                            .fade(duration: 0.5)
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: headerHeight)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: currentIndex)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.tint.opacity(0.2), Color.background],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
    }
    
    var gradientOverlay: some View {
        LinearGradient(
            stops: [
                .init(color: Color.background.opacity(0), location: 0.0),
                .init(color: Color.background.opacity(0.3), location: 0.4),
                .init(color: Color.background.opacity(0.8), location: 0.7),
                .init(color: Color.background, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Computed Properties

private extension SourceHeaderView {
    var host: Host? {
        try? DatabaseProvider.shared.reader.read { db in
            try Host.fetchOne(db, key: source.hostId)
        }
    }
}

// MARK: - Methods

private extension SourceHeaderView {
    func cycleImages() {
        guard artworkUrls.count > 1 else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentIndex = (currentIndex + 1) % artworkUrls.count
        }
    }
    
    func performPing() async {
        guard let host = host else { return }
        
        let pingUrl = URL.appendingPaths(host.baseUrl, source.path, "ping")?.absoluteString ?? ""
        guard let url = URL(string: pingUrl) else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            pingStatus = .loading
        }
        
        do {
            let ns = NetworkService()
            let result = try await ns.ping(url: url)
            withAnimation(.easeInOut(duration: 0.3)) {
                pingStatus = .success(result)
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.3)) {
                pingStatus = .failed
            }
        }
    }
    
    func prefetchImages() {
        let urls = artworkUrls.compactMap { URL(string: $0) }
        
        prefetcher?.stop()
        prefetcher = ImagePrefetcher(
            urls: urls,
            options: KingfisherProvider.prefetchOptions
        )
        prefetcher?.start()
    }
}

// MARK: - PingStatus

private extension SourceHeaderView {
    enum PingStatus {
        case idle
        case loading
        case success(TimeInterval)
        case failed
        
        var color: Color {
            switch self {
            case .idle:
                return .gray
            case .loading:
                return .orange
            case .success:
                return .green
            case .failed:
                return .red
            }
        }
        
        var symbolName: String {
            switch self {
            case .idle:
                return "circle.dotted"
            case .loading:
                return "antenna.radiowaves.left.and.right"
            case .success:
                return "wifi"
            case .failed:
                return "wifi.slash"
            }
        }
        
        var isAnimating: Bool {
            switch self {
            case .idle, .failed:
                return false
            case .loading, .success:
                return true
            }
        }
        
        var displayText: String {
            switch self {
            case .idle:
                return "Idle"
            case .loading:
                return "Pinging..."
            case .success(let time):
                return String(format: "%.0fms", time * 1000)
            case .failed:
                return "Offline"
            }
        }
    }
}

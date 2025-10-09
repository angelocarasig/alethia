//
//  SourcesView.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Domain

struct SourcesView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let origins: [Origin]
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            DetailHeader(title: "Sources")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // vertical timeline with origins
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(origins.enumerated()), id: \.element.id) { index, origin in
                    originNode(
                        origin: origin,
                        isFirst: index == 0,
                        isLast: index == origins.count - 1
                    )
                }
            }
            .padding(.leading, dimensions.padding.regular)
        }
        .padding(.vertical, dimensions.padding.regular)
    }
    
    @ViewBuilder
    private func originNode(origin: Origin, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: dimensions.spacing.large) {
            // timeline connector
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.15))
                        .frame(width: 2, height: 16)
                }
                
                // node indicator with icon
                ZStack {
                    Circle()
                        .fill(theme.colors.background)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .stroke(theme.colors.foreground.opacity(0.2), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    if let source = origin.source {
                        SourceIcon(url: source.icon.absoluteString, isDisabled: source.disabled)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "questionmark")
                            .font(.caption2)
                            .foregroundColor(theme.colors.foreground.opacity(0.3))
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.15))
                        .frame(width: 2)
                        .frame(minHeight: 20)
                }
            }
            
            // content
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                HStack(alignment: .center) {
                    // left side info
                    VStack(alignment: .leading, spacing: 2) {
                        if let source = origin.source {
                            Text(source.name)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.foreground)
                            
                            Text(source.host)
                                .lineLimit(2)
                                .font(.caption2)
                                .foregroundColor(theme.colors.foreground.opacity(0.4))
                        } else {
                            Text("Disconnected Source")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.foreground.opacity(0.5))
                        }
                    }
                    
                    // horizontal connecting line
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, dimensions.padding.regular)
                    
                    // right side stats
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Priority #\(origin.priority + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.foreground)
                        
                        if origin.priority == 0 {
                            Text("Primary")
                                .font(.caption2)
                                .foregroundColor(theme.colors.appYellow)
                        }
                    }
                    
                    // menu button
                    Menu {
                        Group {
                            if let source = origin.source {
                                Link(destination: source.url) {
                                    Label("View on Source", systemImage: "arrow.up.forward.square")
                                }
                            } else {
                                Button {} label: {
                                    Label("View on Source", systemImage: "arrow.up.forward.square")
                                }
                                .disabled(true)
                            }
                        }
                        
                        Button {} label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        
                        Divider()
                        
                        Button {} label: {
                            Label("Set as Primary", systemImage: "star.fill")
                        }
                        .disabled(origin.priority == 0)
                        
                        Button {} label: {
                            Label("Change Priority", systemImage: "arrow.up.arrow.down")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {} label: {
                            Label("Remove", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(theme.colors.foreground.opacity(0.5))
                            .padding(dimensions.padding.regular)
                            .background(theme.colors.tint)
                            .clipShape(Circle())
                    }
                }
                
                // badges row
                HStack(spacing: dimensions.spacing.minimal) {
                    badge(text: origin.classification.rawValue, color: origin.classification.themeColor(using: theme))
                    badge(text: origin.status.rawValue, color: origin.status.themeColor(using: theme))
                    
                    if let source = origin.source {
                        if source.pinned {
                            badge(text: "PINNED", color: theme.colors.appGreen)
                        }
                        
                        if source.disabled {
                            badge(text: "DISABLED", color: theme.colors.appRed)
                        }
                    }
                }
                .padding(.top, dimensions.spacing.minimal)
            }
            .padding(.bottom, isLast ? 0 : dimensions.padding.regular)
        }
        .opacity(origin.source?.disabled ?? false ? 0.5 : 1.0)
    }
    
    @ViewBuilder
    private func badge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
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
            
            SourcesView(
                origins: [
                    Origin(
                        id: 1,
                        slug: "manga-slug-1",
                        url: URL(string: "https://mangadex.org/title/123")!,
                        priority: 0,
                        classification: .Safe,
                        status: .Ongoing,
                        source: Source(
                            id: 1,
                            slug: "mangadex",
                            name: "MangaDex",
                            icon: URL(string: "https://mangadex.org/img/mangadex-logo.svg")!,
                            url: URL(string: "https://api.mangadex.org")!,
                            repository: URL(string: "https://github.com/example/mangadex")!,
                            pinned: true,
                            disabled: false,
                            host: "@official/mangadex",
                            auth: .none,
                            search: Search(
                                supportedSorts: [],
                                supportedFilters: [],
                                tags: [],
                                presets: []
                            ),
                            presets: []
                        )
                    ),
                    Origin(
                        id: 2,
                        slug: "manga-slug-2",
                        url: URL(string: "https://mangasee123.com/manga/123")!,
                        priority: 1,
                        classification: .Suggestive,
                        status: .Completed,
                        source: Source(
                            id: 2,
                            slug: "mangasee",
                            name: "MangaSee",
                            icon: URL(string: "https://mangasee123.com/media/favicon.png")!,
                            url: URL(string: "https://mangasee123.com")!,
                            repository: URL(string: "https://github.com/example/mangasee")!,
                            pinned: false,
                            disabled: false,
                            host: "@community/mangasee",
                            auth: .apiKey(fields: ApiKeyAuthFields(apiKey: "")),
                            search: Search(
                                supportedSorts: [],
                                supportedFilters: [],
                                tags: [],
                                presets: []
                            ),
                            presets: []
                        )
                    ),
                    Origin(
                        id: 3,
                        slug: "manga-slug-3",
                        url: URL(string: "https://manganelo.com/manga/123")!,
                        priority: 2,
                        classification: .Explicit,
                        status: .Hiatus,
                        source: Source(
                            id: 3,
                            slug: "manganelo",
                            name: "Manganelo",
                            icon: URL(string: "https://manganelo.com/favicon.ico")!,
                            url: URL(string: "https://manganelo.com")!,
                            repository: URL(string: "https://github.com/example/manganelo")!,
                            pinned: false,
                            disabled: true,
                            host: "@community/manganelo",
                            auth: .none,
                            search: Search(
                                supportedSorts: [],
                                supportedFilters: [],
                                tags: [],
                                presets: []
                            ),
                            presets: []
                        )
                    ),
                    Origin(
                        id: 4,
                        slug: "disconnected-slug",
                        url: URL(string: "https://example.com/manga/123")!,
                        priority: 3,
                        classification: .Unknown,
                        status: .Cancelled,
                        source: nil
                    )
                ]
            )
            .padding(.horizontal)
            
            Text("Content Below")
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
        }
    }
}

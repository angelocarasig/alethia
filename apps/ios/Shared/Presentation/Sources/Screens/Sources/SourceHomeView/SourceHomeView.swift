//
//  SourceHomeView.swift
//  Presentation
//
//  Created by Angelo Carasig on 5/10/2025.
//

import SwiftUI
import Domain

public struct SourceHomeView: View {
    let source: Source
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    public init(source: Source) {
        self.source = source
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // geometric header with diagonal line
                geometricHeader
                
                // stats bar with vertical dividers
                statsBar
                    .padding(.vertical, dimensions.padding.screen)
                
                // main content with line frames
                mainContent
                
                Spacer(minLength: dimensions.spacing.screen)
            }
        }
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    Text("TODO")
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
    
    private var geometricHeader: some View {
        ZStack(alignment: .topLeading) {
            // background with subtle grid pattern
            Rectangle()
                .fill(theme.colors.background)
                .frame(height: 200)
                .overlay(
                    GeometryReader { geo in
                        Path { path in
                            // horizontal lines
                            for i in stride(from: 0, through: geo.size.height, by: 20) {
                                path.move(to: CGPoint(x: 0, y: i))
                                path.addLine(to: CGPoint(x: geo.size.width, y: i))
                            }
                            // vertical lines
                            for i in stride(from: 0, through: geo.size.width, by: 20) {
                                path.move(to: CGPoint(x: i, y: 0))
                                path.addLine(to: CGPoint(x: i, y: geo.size.height))
                            }
                        }
                        .stroke(theme.colors.foreground.opacity(0.03), lineWidth: 0.5)
                    }
                )
            
            // content
            VStack(spacing: 0) {
                // top section - icon, name, and host
                HStack(alignment: .top, spacing: dimensions.spacing.screen) {
                    // icon
                    SourceIcon(url: source.icon.absoluteString, isDisabled: source.disabled)
                        .frame(dimensions.icon.large)
                        .scaleEffect(1.5)
                        .segmentedStroke(
                            segments: 6,
                            gapAngle: 32,
                            color: theme.colors.foreground.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 88, height: 88)
                    
                    // name and host
                    VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                        Text(source.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text(source.host)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .overlay(
                                Rectangle()
                                    .fill(theme.colors.foreground.opacity(0.2))
                                    .frame(height: 1)
                                    .offset(y: 10)
                            )
                        
                        // status tags
                        HStack(spacing: dimensions.spacing.regular) {
                            if source.pinned {
                                angledTag(text: "PINNED", color: theme.colors.appGreen)
                            }
                            if source.disabled {
                                angledTag(text: "DISABLED", color: theme.colors.appRed)
                            }
                        }
                        .padding(.vertical, dimensions.spacing.minimal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // bottom section - statistics aligned to right
                VStack(alignment: .trailing, spacing: dimensions.spacing.regular) {
                    statLine(value: "247", label: "IN LIBRARY", icon: "books.vertical.fill")
                    statLine(value: "1.2K", label: "CHAPTERS READ", icon: "bookmark.fill")
                    statLine(value: "67.0%", label: "TRACKED", icon: "checkmark.seal.fill")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(dimensions.padding.screen)
        }
        .frame(height: 200)
    }

    private func statLine(value: String, label: String, icon: String) -> some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(theme.colors.foreground.opacity(0.3))
            
            Text(value)
                .font(.footnote)
                .fontWeight(.black)
                .foregroundColor(theme.colors.foreground)
            
            Text(label)
                .font(.caption2)
                .fontWeight(.regular)
                .foregroundColor(theme.colors.foreground.opacity(0.5))
                .padding(.leading, 2)
        }
    }

    private func cornerBracket(rotation: Double) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 0))
        }
        .stroke(theme.colors.foreground.opacity(0.3), lineWidth: 1)
        .frame(width: 10, height: 10)
        .rotationEffect(.degrees(rotation))
    }
    
    private func angledTag(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(color)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.15), color.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color, lineWidth: 1)
                    )
            )
    }
    
    private var statsBar: some View {
        ZStack {
            // content
            HStack(spacing: 0) {
                statItem(
                    icon: "hexagon",
                    value: "\(source.presets.count)",
                    label: "PRESETS"
                )
                
                Rectangle()
                    .fill(theme.colors.foreground.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, dimensions.padding.regular)
                
                statItem(
                    icon: source.auth != .none ? "lock.fill" : "lock.open",
                    value: source.auth.displayText.uppercased().replacingOccurrences(of: "AUTH", with: ""),
                    label: "AUTH"
                )
                
                Rectangle()
                    .fill(theme.colors.foreground.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, dimensions.padding.regular)
                
                statItem(
                    icon: "circle.fill",
                    value: "67ms",
                    label: "PING",
                    valueColor: theme.colors.appGreen
                )
            }
            .frame(height: 60)
            
            // corner brackets overlay
            VStack {
                HStack {
                    cornerBracket(rotation: 0)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    cornerBracket(rotation: 90)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                HStack {
                    cornerBracket(rotation: 270)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    cornerBracket(rotation: 180)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 60)
        }
        .padding(.horizontal, dimensions.padding.screen)
    }
    
    private func statItem(icon: String, value: String, label: String, valueColor: Color? = nil) -> some View {
        VStack(spacing: dimensions.spacing.minimal) {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(theme.colors.foreground.opacity(0.4))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(valueColor ?? theme.colors.foreground)
            }
            
            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(theme.colors.foreground.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
            // info section with line list
            VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                sectionHeader(title: "INFORMATION", count: nil)
                
                VStack(spacing: 0) {
                    lineItem(label: "Host Provider", value: source.host)
                    lineItem(label: "Base URL", value: source.url.absoluteString)
                    lineItem(label: "Repository", value: source.repository.absoluteString, isLast: true)
                }
            }
            
            // presets section
            if source.presets.count > 0 {
                VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                    sectionHeader(title: "DISCOVER", count: source.presets.count)
                    
                    ForEach(source.presets, id: \.self) { preset in
                        SourceHomeRow(source: source, preset: preset)
                    }
                }
            }
        }
        .padding(dimensions.padding.screen)
    }
    
    private func sectionHeader(title: String, count: Int? = nil) -> some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(theme.colors.foreground.opacity(0.6))
            
            if let count = count {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(theme.colors.foreground.opacity(0.3))
            }
            
            // horizontal line after text
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(theme.colors.foreground.opacity(0.1), lineWidth: 1)
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func lineItem(label: String, value: String, isLast: Bool = false) -> some View {
        HStack {
            // bullet line
            HStack(spacing: dimensions.spacing.regular) {
                Circle()
                    .fill(theme.colors.foreground.opacity(0.2))
                    .frame(width: 4, height: 4)
                
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            // value aligned to trailing
            Group {
                // check if value is a valid url
                if let url = URL(string: value),
                   (url.scheme == "http" || url.scheme == "https") {
                    Link(destination: url) {
                        HStack(spacing: 2) {
                            Text(value)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(theme.colors.accent)
                                .underline()
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Image(systemName: "arrow.up.forward.square")
                                .font(.caption2)
                                .foregroundColor(theme.colors.accent.opacity(0.7))
                        }
                    }
                } else {
                    Text(value)
                        .font(.footnote)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, dimensions.padding.regular)
        .overlay(
            Group {
                if !isLast {
                    // connecting line to next item
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.1))
                        .frame(width: 1)
                        .padding(.leading, 2)
                        .offset(y: 20)
                }
            },
            alignment: .leading
        )
    }
}

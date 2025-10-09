//
//  MetadataView.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI
import Domain

struct MetadataView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let classification: Classification
    let status: Status
    let addedAt: Date
    let updatedAt: Date
    let lastFetchedAt: Date
    let lastReadAt: Date
    
    var body: some View {
        VStack(alignment: .center, spacing: dimensions.spacing.large) {
            DetailHeader(title: "Metadata")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: dimensions.spacing.large) {
                // primary info at top
                HStack(spacing: dimensions.spacing.regular) {
                    timelineBadge(
                        text: classification.rawValue,
                        color: classification.themeColor(using: theme)
                    )
                    timelineBadge(
                        text: status.rawValue,
                        color: status.themeColor(using: theme)
                    )
                }
                
                // vertical timeline with stats
                VStack(alignment: .leading, spacing: 0) {
                    timelineNode(
                        label: "Added",
                        value: addedAt.timeAgo(),
                        stat: daysAgo(from: addedAt),
                        statLabel: "days",
                        isFirst: true
                    )
                    timelineNode(
                        label: "Updated",
                        value: updatedAt.timeAgo(),
                        stat: daysAgo(from: updatedAt),
                        statLabel: "days"
                    )
                    timelineNode(
                        label: "Fetched",
                        value: lastFetchedAt.timeAgo(),
                        stat: daysAgo(from: lastFetchedAt),
                        statLabel: "days"
                    )
                    timelineNode(
                        label: "Last Read",
                        value: lastReadAt.timeAgo(),
                        stat: daysAgo(from: lastReadAt),
                        statLabel: "days",
                        isLast: true
                    )
                }
                .padding(.leading, dimensions.padding.regular)
            }
        }
    }
    
    private func timelineBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, dimensions.padding.minimal)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
    
    private func timelineNode(
        label: String,
        value: String,
        stat: String,
        statLabel: String,
        isFirst: Bool = false,
        isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: dimensions.spacing.regular) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.15))
                        .frame(width: 2, height: 16)
                }
                
                Circle()
                    .fill(theme.colors.foreground.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                if !isLast {
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.15))
                        .frame(width: 2)
                        .frame(minHeight: 20)
                }
            }
            
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.caption)
                            .foregroundColor(theme.colors.foreground.opacity(0.6))
                        
                        Text(value)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.foreground)
                    }
                    
                    // horizontal connecting line
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.1))
                        .frame(height: 1)
                        .padding()
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(stat)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.colors.foreground)
                        
                        Text(statLabel)
                            .font(.caption2)
                            .foregroundColor(theme.colors.foreground.opacity(0.4))
                    }
                }
            }
            .padding(.bottom, isLast ? 0 : dimensions.padding.regular)
        }
    }
    
    private func daysAgo(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
        return "\(days)"
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
            
            MetadataView(
                classification: .Suggestive,
                status: .Completed,
                addedAt: Calendar.current.date(byAdding: .year, value: -7, to: .now)!,
                updatedAt: Calendar.current.date(byAdding: .year, value: -3, to: .now)!,
                lastFetchedAt: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
                lastReadAt: Calendar.current.date(byAdding: .day, value: -7, to: .now)!
            )
            .padding(.horizontal)
            
            Text("Content Below")
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.2))
        }
    }
}

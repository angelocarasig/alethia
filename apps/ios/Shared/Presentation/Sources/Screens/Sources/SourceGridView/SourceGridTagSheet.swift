//
//  SourceGridTagSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 19/10/2025.
//

import SwiftUI
import Domain

struct SourceGridTagSheet: View {
    @Binding var includedTags: Set<String>
    @Binding var excludedTags: Set<String>
    let availableTags: [SearchTag]
    let supportsIncludeTags: Bool
    let supportsExcludeTags: Bool
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private var hasActiveTags: Bool {
        !includedTags.isEmpty || !excludedTags.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: dimensions.spacing.screen) {
                    if hasActiveTags {
                        activeTagsSection
                        Divider()
                    }
                    
                    allTagsSection
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if hasActiveTags {
                        Button("Clear All") {
                            withAnimation(theme.animations.spring) {
                                includedTags.removeAll()
                                excludedTags.removeAll()
                            }
                        }
                        .foregroundColor(theme.colors.appRed)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
}

// MARK: - sections

private extension SourceGridTagSheet {
    var activeTagsSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack {
                Text("ACTIVE TAGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                
                Spacer()
                
                Text("\(includedTags.count + excludedTags.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, dimensions.padding.regular)
                    .padding(.vertical, dimensions.padding.minimal)
                    .background(theme.colors.accent)
                    .clipShape(.capsule)
            }
            
            activeTagsFlow
        }
    }
    
    @ViewBuilder
    private var activeTagsFlow: some View {
        let activeTagsList: [(tag: SearchTag, isIncluded: Bool)] = {
            var list: [(SearchTag, Bool)] = []
            
            for slug in includedTags {
                if let tag = availableTags.first(where: { $0.slug == slug }) {
                    list.append((tag, true))
                }
            }
            
            for slug in excludedTags {
                if let tag = availableTags.first(where: { $0.slug == slug }) {
                    list.append((tag, false))
                }
            }
            
            return list
        }()
        
        FlowLayout(spacing: dimensions.spacing.regular) {
            ForEach(activeTagsList, id: \.tag.slug) { item in
                ActiveTagChip(
                    tag: item.tag,
                    isIncluded: item.isIncluded,
                    onRemove: {
                        withAnimation(theme.animations.spring) {
                            if item.isIncluded {
                                includedTags.remove(item.tag.slug)
                            } else {
                                excludedTags.remove(item.tag.slug)
                            }
                        }
                    }
                )
            }
        }
    }
    
    var allTagsSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: "tag")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                
                Text("ALL TAGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                
                Spacer()
                
                Text("\(availableTags.count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
            }
            
            FlowLayout(spacing: dimensions.spacing.regular) {
                ForEach(availableTags, id: \.slug) { tag in
                    TagChip(
                        tag: tag,
                        isIncluded: includedTags.contains(tag.slug),
                        isExcluded: excludedTags.contains(tag.slug),
                        supportsInclude: supportsIncludeTags,
                        supportsExclude: supportsExcludeTags,
                        onTap: {
                            withAnimation(theme.animations.spring) {
                                handleTagTap(tag.slug)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - helper methods

private extension SourceGridTagSheet {
    func handleTagTap(_ slug: String) {
        let isIncluded = includedTags.contains(slug)
        let isExcluded = excludedTags.contains(slug)
        
        // remove from both sets first
        includedTags.remove(slug)
        excludedTags.remove(slug)
        
        // determine next state based on capabilities
        if supportsIncludeTags && supportsExcludeTags {
            // both supported: none -> include -> exclude -> none
            if !isIncluded && !isExcluded {
                includedTags.insert(slug)
            } else if isIncluded {
                excludedTags.insert(slug)
            }
            // if isExcluded, stays removed (goes back to none)
        } else if supportsIncludeTags {
            // only include: none -> include -> none
            if !isIncluded {
                includedTags.insert(slug)
            }
        } else if supportsExcludeTags {
            // only exclude: none -> exclude -> none
            if !isExcluded {
                excludedTags.insert(slug)
            }
        }
    }
}

// MARK: - tag chip

private struct TagChip: View {
    let tag: SearchTag
    let isIncluded: Bool
    let isExcluded: Bool
    let supportsInclude: Bool
    let supportsExclude: Bool
    let onTap: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    private var isActive: Bool {
        isIncluded || isExcluded
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: dimensions.spacing.minimal) {
                stateIcon
                
                Text(tag.name)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(textColor)
                
                if tag.nsfw {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(theme.colors.appRed.opacity(0.8))
                }
            }
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular)
            .background(backgroundColor)
            .cornerRadius(dimensions.cornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                    .strokeBorder(borderColor, lineWidth: isActive ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var stateIcon: some View {
        if isIncluded {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(theme.colors.appGreen)
        } else if isExcluded {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(theme.colors.appRed)
        } else {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundColor(theme.colors.foreground.opacity(0.3))
        }
    }
    
    private var backgroundColor: Color {
        if isIncluded {
            return theme.colors.appGreen.opacity(0.1)
        } else if isExcluded {
            return theme.colors.appRed.opacity(0.1)
        } else {
            return theme.colors.tint
        }
    }
    
    private var borderColor: Color {
        if isIncluded {
            return theme.colors.appGreen.opacity(0.3)
        } else if isExcluded {
            return theme.colors.appRed.opacity(0.3)
        } else {
            return theme.colors.foreground.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        if isIncluded {
            return theme.colors.appGreen
        } else if isExcluded {
            return theme.colors.appRed
        } else {
            return theme.colors.foreground
        }
    }
}

// MARK: - active tag chip

private struct ActiveTagChip: View {
    let tag: SearchTag
    let isIncluded: Bool
    let onRemove: () -> Void
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        HStack(spacing: dimensions.spacing.minimal) {
            Image(systemName: isIncluded ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(isIncluded ? theme.colors.appGreen : theme.colors.appRed)
            
            Text(tag.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isIncluded ? theme.colors.appGreen : theme.colors.appRed)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(isIncluded ? theme.colors.appGreen.opacity(0.7) : theme.colors.appRed.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .background(isIncluded ? theme.colors.appGreen.opacity(0.15) : theme.colors.appRed.opacity(0.15))
        .cornerRadius(dimensions.cornerRadius.button)
        .overlay(
            RoundedRectangle(cornerRadius: dimensions.cornerRadius.button)
                .strokeBorder(isIncluded ? theme.colors.appGreen : theme.colors.appRed, lineWidth: 1.5)
        )
    }
}

// MARK: - flow layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.frames[index].minX + bounds.minX,
                                      y: result.frames[index].minY + bounds.minY),
                          proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

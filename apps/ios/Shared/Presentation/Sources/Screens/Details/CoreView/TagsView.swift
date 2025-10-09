//
//  File.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI


struct TagsView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var showAllTags: Bool = false
    
    let tags: [String]
    
    let visibleTagsCount: Int = 8
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            let visibleTags = showAllTags ? tags : Array(tags.prefix(visibleTagsCount))
            
            FlowLayout(spacing: dimensions.spacing.regular) {
                ForEach(visibleTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, dimensions.padding.regular + dimensions.padding.minimal)
                        .padding(.vertical, dimensions.padding.regular)
                        .foregroundStyle(theme.colors.foreground.opacity(0.8))
                        .background(theme.colors.tint)
                        .clipShape(.capsule)
                }
            }
            
            if tags.count > visibleTagsCount {
                Button {
                    withAnimation(theme.animations.spring) {
                        showAllTags.toggle()
                    }
                } label: {
                    HStack(spacing: dimensions.spacing.minimal) {
                        Spacer()
                        Image(systemName: showAllTags ? "chevron.up" : "chevron.down")
                        Text(showAllTags ? "Show Less" : "Show More")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.colors.accent)
                }
            }
        }
    }
}

// MARK: - Flow Layout
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

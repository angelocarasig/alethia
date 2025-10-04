//
//  Banner.swift
//  Presentation
//
//  Created by Angelo Carasig on 30/6/2025.
//

import SwiftUI

internal struct Banner: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let action: (() -> Void)?
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    // Optional customization
    var iconFont: Font = .title3
    var isLoading: Bool = false
    var rightContent: AnyView?
    var isDisabled: Bool = false
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        color: Color,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.action = action
    }
    
    var body: some View {
        content
            .if(action != nil && !isDisabled) { view in
                view.tappable {
                    action?()
                }
            }
    }
    
    private var content: some View {
        HStack(spacing: dimensions.spacing.regular) {
            Image(systemName: icon)
                .font(iconFont)
                .foregroundColor(color)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.colors.foreground.opacity(0.7))
                }
            }
            
            Spacer()
            
            if let rightContent {
                rightContent
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .tint(color)
            } else if action != nil && !isDisabled {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color.opacity(0.6))
            }
        }
        .padding(dimensions.padding.screen)
        .background(color.opacity(0.1))
        .cornerRadius(dimensions.cornerRadius.button)
        .opacity(isDisabled && !isLoading ? 0.6 : 1)
    }
}

// MARK: - Banner Extensions
extension Banner {
    func iconFont(_ font: Font) -> Banner {
        var banner = self
        banner.iconFont = font
        return banner
    }
    
    func loading(_ isLoading: Bool) -> Banner {
        var banner = self
        banner.isLoading = isLoading
        return banner
    }
    
    func disabled(_ isDisabled: Bool) -> Banner {
        var banner = self
        banner.isDisabled = isDisabled
        return banner
    }
    
    func rightContent<Content: View>(@ViewBuilder _ content: () -> Content) -> Banner {
        var banner = self
        banner.rightContent = AnyView(content())
        return banner
    }
}

//
//  File.swift
//  Presentation
//
//  Created by Angelo Carasig on 21/6/2025.
//

import SwiftUI
import Kingfisher
import Core
import Domain

internal struct SourceIcon: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let url: String
    let isDisabled: Bool
    
    var body: some View {
        KFImage(URL(smartPath: url))
            .placeholder {
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .fill(theme.colors.foreground.opacity(0.05))
                    .frame(dimensions.icon.regular)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(theme.colors.foreground.opacity(0.2))
                    }
            }
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(dimensions.icon.regular)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular))
            .opacity(isDisabled ? 0.5 : 1.0)
    }
}

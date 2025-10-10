//
//  AlternativeTitlesSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI

struct AlternativeTitlesSheet: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let primaryTitle: String
    let alternativeTitles: [String]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.large) {
                    // primary title section
                    VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(theme.colors.appYellow)
                            
                            Text("PRIMARY TITLE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.foreground.opacity(0.6))
                        }
                        
                        titleCard(
                            primaryTitle,
                            icon: "checkmark.seal.fill",
                            color: theme.colors.accent
                        )
                    }
                    
                    if !alternativeTitles.isEmpty {
                        Divider()
                        
                        // alternative titles section
                        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                            HStack {
                                Image(systemName: "character.book.closed")
                                    .font(.caption)
                                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                                
                                Text("ALTERNATIVE TITLES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                                
                                Spacer()
                                
                                Text("\(alternativeTitles.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.colors.accent)
                                    .padding(.horizontal, dimensions.padding.regular)
                                    .padding(.vertical, dimensions.padding.minimal)
                                    .background(theme.colors.accent.opacity(0.1))
                                    .clipShape(.capsule)
                            }
                            
                            VStack(spacing: dimensions.spacing.regular) {
                                ForEach(Array(alternativeTitles.enumerated()), id: \.offset) { index, altTitle in
                                    titleCard(
                                        altTitle,
                                        icon: "text.quote",
                                        color: theme.colors.foreground.opacity(0.6)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Titles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    @ViewBuilder
    private func titleCard(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: dimensions.spacing.regular) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = title
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                    .padding(dimensions.padding.regular)
                    .background(theme.colors.tint)
                    .clipShape(Circle())
            }
        }
        .padding(dimensions.padding.screen)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .contextMenu {
            Button {
                UIPasteboard.general.string = title
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                // TODO: search for this title
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview("With Alternative Titles") {
    AlternativeTitlesSheet(
        primaryTitle: "Solo Leveling",
        alternativeTitles: [
            "나 혼자만 레벨업",
            "Only I Level Up",
            "俺だけレベルアップな件",
            "Ore Dake Level Up na Ken",
            "I Alone Level-Up",
            "Na Honjaman Lebel-eob"
        ]
    )
}

#Preview("No Alternative Titles") {
    AlternativeTitlesSheet(
        primaryTitle: "One Piece",
        alternativeTitles: []
    )
}

#Preview("Single Alternative") {
    AlternativeTitlesSheet(
        primaryTitle: "Attack on Titan",
        alternativeTitles: ["進撃の巨人"]
    )
}

//
//  MangaDisambiguationView.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI
import Domain
import Kingfisher

struct MangaDisambiguationView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let matches: [Manga]
    let onSelect: (Manga) -> Void
    let onCreateNew: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // header with count
            HStack {
                VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                    Text("Multiple Matches Found")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(matches.count) manga share this title")
                        .font(.caption)
                        .foregroundColor(theme.colors.foreground.opacity(0.6))
                }
                
                Spacer()
            }
            .padding(dimensions.padding.screen)
            
            // horizontal line
            Rectangle()
                .fill(theme.colors.foreground.opacity(0.1))
                .frame(height: 1)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.element.id) { index, manga in
                        matchCard(manga: manga)
                        
                        if index < matches.count - 1 {
                            Rectangle()
                                .fill(theme.colors.foreground.opacity(0.05))
                                .frame(height: 1)
                                .padding(.leading, 120)
                        }
                    }
                    
                    // create new option
                    Rectangle()
                        .fill(theme.colors.foreground.opacity(0.1))
                        .frame(height: 1)
                    
                    createNewCard()
                }
            }
        }
    }
    
    @ViewBuilder
    private func matchCard(manga: Manga) -> some View {
        HStack(spacing: dimensions.spacing.screen) {
            // cover
            KFImage(manga.covers.firstOrDefault)
                .placeholder { theme.colors.tint.shimmer() }
                .resizable()
                .coverCache()
                .scaledToFill()
                .frame(width: 70, height: 100)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular))
            
            // info
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                Text(manga.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(manga.authors.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                    .lineLimit(1)
                
                HStack(spacing: dimensions.spacing.minimal) {
                    pill(text: "\(manga.origins.count) sources")
                    pill(text: "\(manga.chapters.count) chapters")
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.colors.foreground.opacity(0.3))
        }
        .padding(dimensions.padding.screen)
        .contentShape(Rectangle())
        .tappable {
            onSelect(manga)
        }
    }
    
    @ViewBuilder
    private func createNewCard() -> some View {
        HStack(spacing: dimensions.spacing.screen) {
            // icon
            ZStack {
                RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular)
                    .fill(theme.colors.accent.opacity(0.1))
                    .frame(width: 70, height: 100)
                
                Image(systemName: "plus.square.dashed")
                    .font(.title2)
                    .foregroundColor(theme.colors.accent)
            }
            
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                Text("Create New Entry")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Treat this as a unique manga")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.6))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(theme.colors.accent.opacity(0.5))
        }
        .padding(dimensions.padding.screen)
        .contentShape(Rectangle())
        .tappable {
            onCreateNew()
        }
    }
    
    @ViewBuilder
    private func pill(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, 4)
            .background(theme.colors.tint)
            .clipShape(.capsule)
    }
}

// MARK: - Preview

#Preview("Multiple Matches") {
    MangaDisambiguationView(
        matches: [
            mockManga(title: "Fate/stay night", authors: ["Type-Moon"], sources: 3, chapters: 85),
            mockManga(title: "Fate/Zero", authors: ["Gen Urobuchi", "Type-Moon"], sources: 2, chapters: 67),
            mockManga(title: "Fate/Grand Order", authors: ["Type-Moon"], sources: 5, chapters: 120),
            mockManga(title: "Fate/Apocrypha", authors: ["Yuichiro Higashide", "Type-Moon"], sources: 2, chapters: 45)
        ],
        onSelect: { manga in
            print("Selected: \(manga.title)")
        },
        onCreateNew: {
            print("Create new entry")
        }
    )
}

// mock helper
private func mockManga(title: String, authors: [String], sources: Int, chapters: Int) -> Manga {
    Manga(
        id: Int64.random(in: 1...1000),
        title: title,
        authors: authors,
        synopsis: AttributedString("Synopsis"),
        alternativeTitles: [],
        tags: [],
        covers: [URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/84eb80c2-4cbe-4fc8-a3e0-b24bf8136473.jpg")!],
        origins: Array(repeating: mockOrigin(), count: sources),
        chapters: Array(repeating: mockChapter(), count: chapters),
        collections: [],
        inLibrary: false,
        addedAt: .now,
        updatedAt: .now,
        lastFetchedAt: .now,
        lastReadAt: .now,
        orientation: .leftToRight,
        showAllChapters: true,
        showHalfChapters: false
    )
}

private func mockOrigin() -> Origin {
    Origin(
        id: Int64.random(in: 1...1000),
        slug: "slug",
        url: URL(string: "https://example.com")!,
        priority: 0,
        classification: .Safe,
        status: .Ongoing,
        source: nil
    )
}

private func mockChapter() -> Chapter {
    Chapter(
        id: Int64.random(in: 1...1000),
        slug: "slug",
        title: "Chapter",
        number: 1,
        date: .now,
        scanlator: "Scanlator",
        language: LanguageCode("en"),
        url: "https://example.com",
        icon: nil,
        progress: 0
    )
}

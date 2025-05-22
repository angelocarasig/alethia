//
//  ContinueReadingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import SwiftUI

struct ContinueReadingView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var targetChapter: ChapterExtended? {
        vm.details?.chapters
            .sorted { $0.chapter.number < $1.chapter.number }
            .first(where: { !$0.chapter.read })
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Group {
                    if let chapter = targetChapter, let index = vm.details?.chapters.firstIndex(of: chapter) {
                        ChaptersExisting(chapter: chapter, index: index)
                    } else {
                        AllChaptersRead()
                    }
                }
            }
        }
        .redacted(reason: vm.details == nil ? .placeholder : [])
        .padding(Constants.Padding.screen)
    }
    
    @ViewBuilder
    private func ChaptersExisting(chapter: ChapterExtended, index: Int) -> some View {
        NavigationLink {
            if let chapter = targetChapter {
                ReaderScreen(
                    mangaTitle: vm.details?.manga.title ?? "Unknown Title",
                    orientation: vm.details?.manga.orientation ?? .LeftToRight,
                    currentChapter: chapter,
                    chapters: vm.details?.chapters ?? []
                )
            }
            else {
                EmptyView()
            }
        } label: {
            HStack(spacing: Constants.Spacing.large) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                
                VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                    Text(index == vm.details.unsafelyUnwrapped.chapters.count - 1 ? "Start" : "Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Chapter \(chapter.chapter.number.toString())")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, Constants.Padding.regular)
            .padding(.horizontal, Constants.Padding.screen)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                        .fill(Color.appBlue.opacity(0.9))
                    
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                        .stroke(Color.appBlue, lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func AllChaptersRead() -> some View {
        HStack(spacing: Constants.Spacing.regular) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18, weight: .bold))
            
            VStack(alignment: .center, spacing: Constants.Spacing.minimal) {
                Text("All Chapters")
                Text("Read")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
                
        }
        .padding(.vertical, Constants.Padding.regular)
        .padding(.horizontal, Constants.Padding.screen)
        .background(
            RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                .fill(.ultraThinMaterial)
        )
    }
}

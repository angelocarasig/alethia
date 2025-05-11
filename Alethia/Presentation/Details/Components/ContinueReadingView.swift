//
//  ContinueReadingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import SwiftUI

struct ContinueReadingView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail? {
        vm.details
    }
    
    var targetChapter: ChapterExtended? {
        details?.chapters
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
        .redacted(reason: details == nil ? .placeholder : [])
        .padding(16)
    }
    
    @ViewBuilder
    private func ChaptersExisting(chapter: ChapterExtended, index: Int) -> some View {
        NavigationLink(destination: ReaderScreen(
            title: vm.details.unsafelyUnwrapped.manga.title,
            orientation: vm.details.unsafelyUnwrapped.manga.orientation,
            chapters: vm.details.unsafelyUnwrapped.chapters,
            currentChapterIndex: index
        )) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(index == vm.details.unsafelyUnwrapped.chapters.count - 1 ? "Start" : "Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Chapter \(chapter.chapter.number.toString())")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appBlue.opacity(0.9))
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appBlue, lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func AllChaptersRead() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 18, weight: .bold))
            
            VStack(alignment: .center, spacing: 2) {
                Text("All Chapters")
                Text("Read")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
                
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

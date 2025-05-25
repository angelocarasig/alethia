//
//  EndDetails.swift
//  Alethia
//
//  Created by Angelo Carasig on 19/5/2025.
//

import SwiftUI

struct EndDetails: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Spacer().frame(height: 150)
            
            ContentSection()
            
            Spacer()
            
            // TODO: Redesign
//            ChapterSelectionSection()
            
            TrackerSection()
            
            Spacer()
            
            if let recommendations = vm.recommendations {
                Recommendations(recommendations: recommendations)
            }
            
            Spacer().frame(height: 150)
        }
        .padding(.horizontal, Constants.Padding.screen)
        .frame(width: UIScreen.main.bounds.width)
    }
}

// MARK: - Content Section
extension EndDetails {
    @ViewBuilder
    private func ContentSection() -> some View {
        let chapterNumber = "Chapter \(vm.currentChapter.chapter.number.toString())"
        let chapterTitle = vm.currentChapter.chapter.title
        VStack(spacing: Constants.Spacing.large) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                Text("Finished Reading")
                    .fontWeight(.bold)
            }
            .font(.title)
            
            VStack(spacing: Constants.Spacing.large) {
                Text(chapterNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if chapterNumber.localizedCaseInsensitiveCompare(chapterTitle) != .orderedSame {
                    Text(chapterTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(3, reservesSpace: true)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer().frame(height: 50)
            
            GeometryReader { geometry in
                HStack {
                    Button {
                        vm.updateChapterProgress(didCompleteChapter: true) {
                            dismiss()
                        }
                    } label: {
                        Text("Exit")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(width: geometry.size.width * 0.35, alignment: .center)
                            .frame(maxHeight: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(Constants.Corner.Radius.button)
                    }
                    .buttonStyle(.plain)
                    
                    // TODO: Add banner if next chapter skips a value:
                    // - If next chapter is non-decimal and not a by-1 increment
                    // - If next chapter is decimal but >= 2 value difference
                    
                    Button {
                        vm.updateChapterProgress(didCompleteChapter: true) {
                            Task {
                                await vm.loadNextChapter()
                            }
                        }
                    } label: {
                        HStack {
                            Text(vm.canGoForward ? "Next Chapter" : "No Next Chapter")
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.text)
                        .padding()
                        .frame(width: geometry.size.width * 0.6, alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(Color.tint)
                        .cornerRadius(Constants.Corner.Radius.button)
                        .disabled(!vm.canGoForward)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 15)
            }
            .frame(height: 75)
        }
    }
}

// MARK: - Chapter Selection
extension EndDetails {
    @ViewBuilder
    private func ChapterSelectionSection() -> some View {
        let allChapters = vm.chapters.toArray()
        
        VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
            Text("CHAPTERS")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom, Constants.Padding.regular)
            
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    ForEach(allChapters, id: \.chapter.id) { chapter in
                        ChapterRow(chapter: chapter)
                    }
                }
            }
            .frame(maxHeight: 500)
            .background(Color.background)
            .cornerRadius(Constants.Corner.Radius.regular)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.vertical, Constants.Padding.regular)
    }
    
    @ViewBuilder
    private func ChapterRow(chapter: ChapterExtended) -> some View {
        let isCurrentChapter = chapter.chapter.id == vm.currentChapter.chapter.id
        let isBeforeCurrentChapter = chapter.chapter.number < vm.currentChapter.chapter.number
        
        Button {
            if !isCurrentChapter {
                Task {
                    await vm.loadChapter(with: chapter)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Chapter \(chapter.chapter.number.toString())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    if chapter.chapter.title != chapter.chapter.number.toString() {
                        Text(chapter.chapter.title)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isCurrentChapter {
                    Text("Current")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, Constants.Padding.regular)
            .padding(.vertical, 12)
            .background(isCurrentChapter ? Color.accentColor.opacity(0.1) : Color.clear)
            .opacity(isBeforeCurrentChapter ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isCurrentChapter)
    }
}

// MARK: - Tracker Section
extension EndDetails {
    @ViewBuilder
    private func TrackerSection() -> some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
            Text("TRACKERS")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.bottom, Constants.Padding.regular)
            
            HStack {
                // TODO: Use non-stubbed info
                Image("AniList")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .cornerRadius(Constants.Corner.Radius.regular)
                
                VStack(alignment: .leading) {
                    // TODO: Use title from anilist fetch instead
                    Text(vm.mangaTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("Last Updated \n Mon 21st May, 2021")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    SyncingLabel()
                    
                    Text("1/\(999) Chapters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Recommendations
extension EndDetails {
    @ViewBuilder
    private func Recommendations(recommendations: RecommendedEntries) -> some View {
        VStack(spacing: Constants.Spacing.large) {
            if recommendations.withSimilarTags.count > 0 {
                RecommendationRow(title: "YOU MIGHT LIKE", content: recommendations.withSimilarTags)
            }
            
            if recommendations.fromSameCollection.count > 0 {
                RecommendationRow(title: "IN SIMILAR COLLECTIONS", content: recommendations.fromSameCollection)
            }
            
            if recommendations.otherWorksByAuthor.count > 0 {
                RecommendationRow(title: "AUTHORS OTHER WORKS", content: recommendations.otherWorksByAuthor)
            }
            
            if recommendations.otherSeriesByScanlator.count > 0 {
                RecommendationRow(title: "SCANLATORS OTHER SERIES", content: recommendations.otherSeriesByScanlator)
            }
        }
        .padding(.vertical, Constants.Padding.screen)
    }
    
    @ViewBuilder
    private func RecommendationRow(title: String, content: [Entry]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.top, Constants.Padding.regular)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Constants.Spacing.minimal) {
                    ForEach(content, id: \.self) { entry in
                        NavigationLink {
                            DetailsScreen(entry: entry, source: nil)
                        } label: {
                            EntryView(
                                item: entry,
                                downsample: true,
                                lineLimit: 2
                            )
                        }
                        .frame(width: 150)
                        .id(entry.id)
                    }
                }
            }
        }
    }
}

// MARK: - Sync Status Labels
extension EndDetails {
    @ViewBuilder
    private func SyncingLabel() -> some View {
        HStack {
            Text("Syncing")
                .font(.headline)
                .padding(Constants.Padding.regular)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                        .fill(Color.blue.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                .stroke(Color.blue.opacity(0.9), lineWidth: 2)
                        )
                )
                .foregroundColor(Color.blue)
                .cornerRadius(Constants.Corner.Radius.regular)
        }
    }
    
    @ViewBuilder
    private func SyncedLabel() -> some View {
        HStack {
            Text("Synced")
                .font(.headline)
                .padding(Constants.Padding.regular)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                        .fill(Color.green.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                .stroke(Color.green.opacity(0.9), lineWidth: 2)
                        )
                )
                .foregroundColor(Color.green)
                .cornerRadius(Constants.Corner.Radius.regular)
            
            Image(systemName: "checkmark.circle")
                .foregroundColor(Color.green)
        }
    }
    
    @ViewBuilder
    private func ErrorLabel() -> some View {
        HStack {
            Text("Error")
                .font(.headline)
                .padding(Constants.Padding.regular)
                .background(
                    RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                        .fill(Color.red.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                                .stroke(Color.red.opacity(0.9), lineWidth: 2)
                        )
                )
                .foregroundColor(Color.red)
                .cornerRadius(Constants.Corner.Radius.regular)
            
            Image(systemName: "arrow.trianglehead.counterclockwise")
                .foregroundColor(Color.red)
        }
    }
}

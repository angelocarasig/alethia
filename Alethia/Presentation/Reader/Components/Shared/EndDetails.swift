//
//  EndDetails.swift
//  Alethia
//
//  Created by Angelo Carasig on 19/5/2025.
//

import Core
import SwiftUI

struct EndDetails: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: .Spacing.large) {
                // Top padding
                Spacer().frame(height: 60)
                
                ContentSection()
                
                TrackerSection()
                
                if let recommendations = vm.recommendations {
                    Recommendations(recommendations: recommendations)
                }
                
                // Bottom padding
                Spacer().frame(height: 100)
            }
            .padding(.horizontal)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: UIScreen.main.bounds.width)
        .frame(minHeight: UIScreen.main.bounds.height)
    }
}

// MARK: - Content Section
extension EndDetails {
    @ViewBuilder
    private func ContentSection() -> some View {
        let chapterNumber = "Chapter \(vm.currentChapter.chapter.number.toString())"
        let chapterTitle = vm.currentChapter.chapter.title
        let buttonSectionHeight: CGFloat = 65
        
        VStack(spacing: .Spacing.large) {
            // Success indicator
            VStack(spacing: .Spacing.regular) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
                    .imageScale(.medium)
                    .symbolEffect(.pulse, options: .repeating.speed(0.5))
                
                Text("Finished Reading")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            // Chapter info
            VStack(spacing: .Padding.regular) {
                Text(chapterNumber)
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                if chapterNumber.localizedCaseInsensitiveCompare(chapterTitle) != .orderedSame {
                    Text(chapterTitle)
                        .font(.title3)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .fontWeight(.semibold)
            
            Spacer().frame(height: 50)
            
            // Action buttons
            HStack {
                Button {
                    vm.updateChapterProgress(didCompleteChapter: true) {
                        dismiss()
                    }
                } label: {
                    VStack(spacing: .Spacing.minimal) {
                        Image(systemName: "house.fill")
                        Text("Exit")
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .font(.headline)
                .fontWeight(.semibold)
                .padding()
                .frame(width: 150, height: buttonSectionHeight)
                .background(Color.secondary.opacity(0.2))
                .foregroundStyle(Color.primary)
                .cornerRadius(.Corner.button)
                
                // TODO: Add banner if next chapter skips a value:
                // - If next chapter is non-decimal and not a by-1 increment
                // - If next chapter is decimal but >= 2 value difference
                
                Button {
                    if vm.canGoForward {
                        vm.updateChapterProgress(didCompleteChapter: true) {
                            Task {
                                await vm.loadNextChapter()
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(vm.canGoForward ? "Next Chapter" : "No Next Chapter.")
                        if vm.canGoForward {
                            Image(systemName: "chevron.right")
                                .imageScale(.medium)
                                .symbolEffect(.pulse, options: .repeating.speed(0.25))
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonSectionHeight)
                    .foregroundStyle(vm.canGoForward ? Color.text : Color.secondary)
                    .background(vm.canGoForward ? Color.accentColor : Color.tint.opacity(0.65))
                    .cornerRadius(.Corner.button)
                    .disabled(!vm.canGoForward)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, .Padding.regular)
        }
        .padding(.vertical)
    }
}

// MARK: - Tracker Section
extension EndDetails {
    @ViewBuilder
    private func TrackerSection() -> some View {
        VStack(alignment: .leading, spacing: .Spacing.large) {
            Text("Tracking")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            GroupBox {
                HStack(spacing: .Spacing.regular) {
                    // Tracker icon
                    Image("AniList")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: .Corner.regular, style: .continuous))
                    
                    // Tracker info
                    VStack(alignment: .leading, spacing: .Spacing.minimal) {
                        Text(vm.mangaTitle)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text("Last synced: May 21, 2021")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Sync status
                    VStack(alignment: .trailing, spacing: .Spacing.minimal) {
                        SyncStatusBadge()
                        
                        Text("1/999")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, .Padding.minimal)
            }
            .groupBoxStyle(CompactGroupBoxStyle())
        }
    }
    
    @ViewBuilder
    private func SyncStatusBadge() -> some View {
        let badgeColor: Color = Color.accentColor
        
        HStack(spacing: .Spacing.minimal) {
            ProgressView()
                .scaleEffect(0.7)
            Text("Syncing")
                .font(.caption)
        }
        .padding(.horizontal, .Padding.regular)
        .padding(.vertical, .Padding.minimal)
        .foregroundStyle(.white)
        .background(badgeColor.opacity(0.75))
        .clipShape(.capsule)
        .overlay(
            Capsule()
                .strokeBorder(badgeColor.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Recommendations
extension EndDetails {
    @ViewBuilder
    private func Recommendations(recommendations: RecommendedEntries) -> some View {
        VStack(alignment: .leading, spacing: .Spacing.large) {
            if !recommendations.withSimilarTags.isEmpty {
                RecommendationSection(
                    title: "You Might Like",
                    systemImage: "sparkles",
                    items: recommendations.withSimilarTags
                )
            }
            
            if !recommendations.fromSameCollection.isEmpty {
                RecommendationSection(
                    title: "Similar Collections",
                    systemImage: "books.vertical",
                    items: recommendations.fromSameCollection
                )
            }
            
            if !recommendations.otherWorksByAuthor.isEmpty {
                RecommendationSection(
                    title: "More by Author",
                    systemImage: "person.crop.circle",
                    items: recommendations.otherWorksByAuthor
                )
            }
            
            if !recommendations.otherSeriesByScanlator.isEmpty {
                RecommendationSection(
                    title: "More by Scanlator",
                    systemImage: "doc.text.magnifyingglass",
                    items: recommendations.otherSeriesByScanlator
                )
            }
        }
    }
    
    @ViewBuilder
    private func RecommendationSection(title: String, systemImage: String, items: [Entry]) -> some View {
        VStack(alignment: .leading, spacing: .Spacing.regular) {
            // Section header
            Label(title, systemImage: systemImage)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: .Spacing.regular) {
                    ForEach(items, id: \.id) { entry in
                        NavigationLink {
                            DetailsScreen(entry: entry, source: nil)
                        } label: {
                            RecommendationCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func RecommendationCard(entry: Entry) -> some View {
        EntryView(item: entry, downsample: true, lineLimit: 2)
            .frame(width: 125)
    }
}

// MARK: - Alternative Sync Status Components
extension EndDetails {
    @ViewBuilder
    private func SyncedBadge() -> some View {
        let badgeColor: Color = Color.green
        
        Label("Synced", systemImage: "checkmark.circle.fill")
            .font(.caption)
            .padding(.horizontal, .Padding.regular)
            .padding(.vertical, .Padding.minimal)
            .foregroundStyle(.white)
            .background(badgeColor.opacity(0.75))
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(badgeColor.opacity(0.2), lineWidth: 1)
            )
    }
    
    @ViewBuilder
    private func ErrorBadge() -> some View {
        let badgeColor: Color = Color.red
        
        Label("Error", systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .padding(.horizontal, .Padding.regular)
            .padding(.vertical, .Padding.minimal)
            .foregroundStyle(.white)
            .background(badgeColor.opacity(0.75))
            .clipShape(.capsule)
            .overlay(
                Capsule()
                    .strokeBorder(badgeColor.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Chapter Selection
extension EndDetails {
    @ViewBuilder
    private func ChapterSelectionSection() -> some View {
        VStack(alignment: .leading, spacing: .Spacing.large) {
            Label("Chapters", systemImage: "list.bullet")
                .font(.headline)
            
            List {
                ForEach(vm.chapters.toArray(), id: \.chapter.id) { chapter in
                    ChapterListRow(chapter: chapter)
                }
            }
            .listStyle(.insetGrouped)
            .frame(maxHeight: 400)
            .scrollContentBackground(.hidden)
        }
    }
    
    @ViewBuilder
    private func ChapterListRow(chapter: ChapterExtended) -> some View {
        let isCurrentChapter = chapter.chapter.id == vm.currentChapter.chapter.id
        
        Button {
            if !isCurrentChapter {
                Task {
                    await vm.loadChapter(with: chapter)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chapter \(chapter.chapter.number.toString())")
                        .font(.subheadline)
                        .fontWeight(isCurrentChapter ? .semibold : .regular)
                    
                    if chapter.chapter.title != chapter.chapter.number.toString() {
                        Text(chapter.chapter.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if isCurrentChapter {
                    Text("Current")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(.capsule)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isCurrentChapter)
        .listRowBackground(
            isCurrentChapter ? Color.accentColor.opacity(0.1) : Color.clear
        )
    }
}

private struct CompactGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
                .padding(.Padding.screen)
        }
        .background(Color.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: .Corner.regular, style: .continuous))
    }
}

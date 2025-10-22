//
//  ChaptersSummaryView.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Domain

struct ChaptersSummaryView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let chapters: [Chapter]
    let sources: Int // number of sources present
    
    @State private var sortBy: SortBy = .number
    @State private var sortOrder: SortOrder = .descending
    @State private var filterMode: FilterMode = .all
    @State private var isSelecting = false
    @State private var selectedChapters: Set<Int64> = []
    
    enum SortBy {
        case date, number
    }
    
    enum SortOrder {
        case ascending, descending
    }
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case downloaded = "Downloaded"
        case reading = "Reading"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
            header
            
            ChaptersSummaryActions(
                chapters: chapters,
                sortBy: $sortBy,
                sortOrder: $sortOrder,
                isSelecting: $isSelecting,
                selectedChapters: $selectedChapters
            )
            
            ChaptersSummaryFilters(
                filterMode: $filterMode
            )
            
            chaptersList
        }
    }
    
    private var filteredAndSortedChapters: [Chapter] {
        let filtered = chapters.filter { chapter in
            switch filterMode {
            case .all: return true
            case .unread: return !chapter.finished && chapter.progress == 0
            case .downloaded: return chapter.downloaded
            case .reading: return chapter.progress > 0 && !chapter.finished
            }
        }
        
        return filtered.sorted { lhs, rhs in
            let comparison: Bool
            switch sortBy {
            case .date:
                comparison = lhs.date > rhs.date
            case .number:
                comparison = lhs.number > rhs.number
            }
            return sortOrder == .descending ? comparison : !comparison
        }
    }
}

// MARK: - Header
extension ChaptersSummaryView {
    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
            Text("Chapters")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: dimensions.spacing.minimal) {
                Text("^[\(chapters.count) Chapter](inflect: true)")
                Text("•")
                Text("^[\(sources) Source](inflect: true)")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(theme.colors.foreground.opacity(0.6))
        }
    }
}

// MARK: - Chapters List
extension ChaptersSummaryView {
    @ViewBuilder
    private var chaptersList: some View {
        if filteredAndSortedChapters.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 0) {
                ForEach(filteredAndSortedChapters, id: \.id) { chapter in
                    Divider()
                    chapterRow(chapter: chapter)
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        ContentUnavailableView(
            "No Chapters",
            systemImage: "book.closed",
            description: Text("No chapters available or match the current filter")
        )
        .frame(height: 200)
    }
    
    @ViewBuilder
    private func chapterRow(chapter: Chapter) -> some View {
        HStack(spacing: dimensions.spacing.large) {
            if isSelecting {
                Image(systemName: selectedChapters.contains(chapter.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedChapters.contains(chapter.id) ? theme.colors.accent : theme.colors.foreground.opacity(0.25))
                    .frame(width: 28)
            }
            NavigationLink {
                ReaderScreen(chapters: chapters, startingChapterSlug: chapter.slug)
            } label: {
                ChapterRow(chapter: chapter)
            }
            .buttonStyle(.plain)
        }
        .opacity(chapter.progress >= 1.0 ? 0.25 : 1.0)
        .padding(.vertical, dimensions.padding.regular)
        .contentShape(.rect)
    }
    
    private func toggleSelection(for chapter: Chapter) {
        if selectedChapters.contains(chapter.id) {
            selectedChapters.remove(chapter.id)
        } else {
            selectedChapters.insert(chapter.id)
        }
    }
}

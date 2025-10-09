//
//  +ChaptersSummaryActions.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Domain

struct ChaptersSummaryActions: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let chapters: [Chapter]
    
    @Binding var sortBy: ChaptersSummaryView.SortBy
    @Binding var sortOrder: ChaptersSummaryView.SortOrder
    @Binding var isSelecting: Bool
    @Binding var selectedChapters: Set<Int64>
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: dimensions.spacing.regular) {
                if isSelecting {
                    selectionBar(height: geometry.size.height)
                } else {
                    defaultBar(height: geometry.size.height)
                }
            }
        }
        .frame(height: 50)
        .animation(theme.animations.spring, value: isSelecting)
    }
}

// MARK: - Default Bar
extension ChaptersSummaryActions {
    @ViewBuilder
    private func defaultBar(height: CGFloat) -> some View {
        // continue/start reading button
        HStack {
            Image(systemName: "play.fill")
                .font(.body)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(chapters.contains { $0.finished || $0.progress > 0 } ? "Continue Reading" : "Start Reading")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let nextChapter = chapters.first(where: { $0.progress < 1.0 }) {
                    Text("Chapter \(Int(nextChapter.number))")
                        .font(.caption)
                        .opacity(0.8)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color.accentColor)
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            // TODO: navigate to reader
        }
        
        // select button
        Image(systemName: "checkmark.square")
            .font(.body)
            .foregroundColor(theme.colors.foreground)
            .frame(width: height, height: height)
            .background(theme.colors.tint)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
            .tappable {
                withAnimation {
                    isSelecting = true
                }
            }
        
        // sort order button
        Image(systemName: sortOrder == .descending ? "arrow.down" : "arrow.up")
            .font(.body)
            .foregroundColor(theme.colors.foreground)
            .frame(width: height, height: height)
            .background(theme.colors.tint)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
            .tappable {
                sortOrder = sortOrder == .descending ? .ascending : .descending
            }
        
        // more options button
        Menu {
            Button {} label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            
            Divider()
            
            Button {
                withAnimation {
                    for chapter in chapters {
                        selectedChapters.insert(chapter.id)
                    }
                    isSelecting = true
                }
            } label: {
                Label("Select All", systemImage: "checkmark.circle")
            }
            
            Divider()
            
            Button {
                sortBy = .date
            } label: {
                if sortBy == .date {
                    Label("Sort by Date", systemImage: "checkmark")
                } else {
                    Text("Sort by Date")
                }
            }

            Button {
                sortBy = .number
            } label: {
                if sortBy == .number {
                    Label("Sort by Number", systemImage: "checkmark")
                } else {
                    Text("Sort by Number")
                }
            }
            
            Divider()
            
            Button {} label: {
                Label("Download All", systemImage: "arrow.down.circle")
            }
            
            Button {} label: {
                Label("Mark All Read", systemImage: "checkmark.circle")
            }
            
            Button {} label: {
                Label("Mark All Unread", systemImage: "circle")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundColor(theme.colors.foreground)
                .frame(width: height, height: height)
                .background(theme.colors.tint)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        }
    }
}

// MARK: - Selection Bar
extension ChaptersSummaryActions {
    @ViewBuilder
    private func selectionBar(height: CGFloat) -> some View {
        // selected count
        HStack(spacing: dimensions.spacing.minimal) {
            Text("\(selectedChapters.count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.accent)
            
            Text("selected")
                .font(.subheadline)
                .foregroundStyle(theme.colors.foreground.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        // save button
        VStack(spacing: 2) {
            Image(systemName: "arrow.down")
                .font(.body)
            Text("Save")
                .font(.caption2)
        }
        .foregroundColor(theme.colors.accent)
        .frame(width: height, height: height)
        .background(theme.colors.accent.opacity(0.1))
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            // TODO: download selected
        }
        
        // delete button
        VStack(spacing: 2) {
            Image(systemName: "trash")
                .font(.body)
            Text("Delete")
                .font(.caption2)
        }
        .foregroundColor(theme.colors.appRed)
        .frame(width: height, height: height)
        .background(theme.colors.appRed.opacity(0.1))
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            // TODO: delete selected
        }
        
        // mark read button
        VStack(spacing: 2) {
            Image(systemName: "book.closed")
                .font(.body)
            Text("Read")
                .font(.caption2)
        }
        .foregroundColor(theme.colors.appGreen)
        .frame(width: height, height: height)
        .background(theme.colors.appGreen.opacity(0.1))
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            // TODO: mark selected as read
        }
        
        // mark unread button
        VStack(spacing: 2) {
            Image(systemName: "book")
                .font(.body)
            Text("Unread")
                .font(.caption2)
        }
        .foregroundColor(theme.colors.appOrange)
        .frame(width: height, height: height)
        .background(theme.colors.appOrange.opacity(0.1))
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            // TODO: mark selected as unread
        }
        
        Spacer().frame(width: 10)
        
        // done button
        VStack(spacing: 2) {
            Image(systemName: "xmark")
                .font(.body)
            Text("Close")
                .font(.caption2)
        }
        .foregroundColor(theme.colors.foreground)
        .frame(width: height, height: height)
        .background(theme.colors.tint.opacity(0.9))
        .clipShape(.rect(cornerRadius: dimensions.cornerRadius.button))
        .tappable {
            withAnimation {
                selectedChapters.removeAll()
                isSelecting = false
            }
        }
    }
}

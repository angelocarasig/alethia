//
//  ChapterListView.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import SwiftUI
import Kingfisher

private extension View {
    func badgeStyle(_ color: Color) -> some View {
        self.font(.caption)
            .foregroundStyle(.white)
            .padding(.vertical, Constants.Padding.minimal)
            .padding(.horizontal, Constants.Padding.regular)
            .background(color)
            .cornerRadius(Constants.Corner.Radius.regular)
    }
}

private struct ChapterHeaderView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var targetChapter: ChapterExtended? {
        vm.chapters
            .sorted { $0.chapter.number < $1.chapter.number }
            .first(where: { !$0.chapter.read })
    }
    
    var targetChapterIndex: Int? {
        guard let targetChapter = targetChapter else { return nil }
        return vm.chapters.firstIndex(of: targetChapter)
    }
    
    var chapterListSourcesCount: Int {
        Set(vm.chapters.map { $0.origin.id }).count
    }
    
    var chapterSourceText: String {
        let chapterText = vm.chapters.count == 1 ? "chapter" : "chapters"
        let sourceText = chapterListSourcesCount == 1 ? "source" : "sources"
        return "\(vm.chapters.count) \(chapterText) from \(chapterListSourcesCount) \(sourceText)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text("Chapters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: Constants.Spacing.minimal) {
                    Text("^[\(vm.chapters.count) Chapter](inflect: true)")
                    Text("•")
                    Text("^[\(chapterListSourcesCount) Source](inflect: true)")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
            
            HStack(spacing: Constants.Spacing.regular) {
                NavigationLink {
                    if let chapter = targetChapter {
                        ReaderScreen(
                            mangaId: vm.details?.manga.id ?? -1,
                            mangaTitle: vm.details?.manga.title ?? "Unknown Title",
                            orientation: vm.resolvedOrientation ?? .LeftToRight,
                            currentChapter: chapter,
                            chapters: vm.details?.chapters ?? []
                        )
                    } else {
                        EmptyView()
                    }
                } label: {
                    if let chapter = targetChapter, let index = targetChapterIndex {
                        HStack(spacing: Constants.Spacing.regular) {
                            Image(systemName: index == (vm.details?.chapters.count ?? 0) - 1 ? "play.fill" : "book.fill")
                                .fontWeight(.semibold)
                            
                            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                                Text(index == (vm.details?.chapters.count ?? 0) - 1 ? "Start Reading" : "Continue")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                
                                Text("Chapter \(chapter.chapter.number.toString())")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, Constants.Padding.regular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Label("All Caught Up", systemImage: "checkmark.circle.fill")
                            .font(.system(.subheadline, weight: .medium))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .disabled(targetChapter == nil)
                .buttonStyle(.borderedProminent)
                
                Button {
                    vm.refreshMetadata()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .fontWeight(.semibold)
                        .foregroundStyle(.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.tint)
                        .clipShape(.rect(cornerRadius: Constants.Corner.Radius.regular))
                }
                .buttonStyle(.plain)
                .aspectRatio(1, contentMode: .fit)
                
                NavigationLink {
                    PriorityManagementView()
                        .environmentObject(vm)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .fontWeight(.semibold)
                        .foregroundStyle(.text)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.tint)
                        .clipShape(.rect(cornerRadius: Constants.Corner.Radius.regular))
                }
                .aspectRatio(1, contentMode: .fit)
            }
            .frame(height: 52) // cringe value
        }
    }
}

struct ChapterListView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    @ObservedObject private var queue = QueueProvider.shared
    
    var body: some View {
        LazyVStack {
            ChapterHeaderView()
                .padding(.bottom, Constants.Padding.minimal)
            
            ForEach(Array(vm.chapters.enumerated()), id: \.element.chapter.id) { index, chapter in
                Divider()
                
                NavigationLink {
                    ReaderScreen(
                        mangaId: vm.details?.manga.id ?? -1,
                        mangaTitle: vm.details?.manga.title ?? "Unknown Title",
                        orientation: vm.resolvedOrientation ?? .LeftToRight,
                        currentChapter: chapter,
                        chapters: vm.details?.chapters ?? []
                    )
                } label: {
                    ChapterRow(
                        item: chapter,
                        operationId: chapter.chapter.queueOperationId
                    )
                    .id("\(chapter.chapter.title)-\(chapter.chapter.progress)-\(chapter.chapter.downloaded)")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, Constants.Padding.screen)
    }
}

struct ChapterRow: View {
    @EnvironmentObject private var vm: DetailsViewModel
    @ObservedObject private var queue = QueueProvider.shared
    let item: ChapterExtended
    let operationId: String
    
    var operation: QueueOperation? {
        queue.operations[operationId]
    }
    
    var read: Bool {
        item.chapter.progress >= 1.0
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.minimal) {
            KFImage(URL(fileURLWithPath: item.source?.icon ?? ""))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .cornerRadius(Constants.Corner.Radius.regular)
                .padding(.trailing, Constants.Padding.regular)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                HStack {
                    Text("Chapter \(item.chapter.number.toString())")
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.chapter.date.toRelativeString())
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                    
                    if item.chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
                        Text("NEW").badgeStyle(.appRed)
                    }
                    
                    if read {
                        Text("Read").badgeStyle(.appOrange)
                    }
                }
                .font(.subheadline)
                
                Text(item.chapter.title)
                    .lineLimit(2)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(item.scanlator.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if item.chapter.progress > 0 && item.chapter.progress != 1 {
                    ProgressView(value: item.chapter.progress)
                        .tint(Color.accentColor)
                        .frame(height: 3)
                        .clipShape(.capsule)
                }
            }
            
            Spacer()
            
            ChapterDownloadButton(
                chapter: item.chapter,
                operationId: operationId
            )
        }
        .padding(.vertical, Constants.Padding.minimal)
        .overlay {
            if read {
                Color.background.opacity(0.3)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(.rect)
        .contextMenu {
            ContextMenu()
        }
    }
    
    // MARK: - Context Menu Actions
    
    @ViewBuilder
    private func ContextMenu() -> some View {
        ControlGroup {
            Button {
                vm.markChapter(asRead: true, for: item)
            } label: {
                Label("Mark Read", systemImage: "book.closed")
            }.disabled(item.chapter.read)
            
            Button {
                vm.markAllChaptersAbove(from: item, asRead: true)
            } label: {
                Label("Read Above", systemImage: "arrow.up.square.fill")
            }
            
            Button {
                vm.markAllChaptersBelow(from: item, asRead: true)
            } label: {
                Label("Read Below", systemImage: "arrow.down.square.fill")
            }
        }
        
        ControlGroup {
            Button {
                vm.markChapter(asRead: false, for: item)
            } label: {
                Label("Mark Unread", systemImage: "book")
            }.disabled(!item.chapter.read)
            
            Button {
                vm.markAllChaptersAbove(from: item, asRead: false)
            } label: {
                Label("Unread Above", systemImage: "arrow.up.square")
            }
            
            Button {
                vm.markAllChaptersBelow(from: item, asRead: false)
            } label: {
                Label("Unread Below", systemImage: "arrow.down.square")
            }
        }
        
        ControlGroup {
            Button {
                vm.downloadChapter(item.chapter)
            } label: {
                Label("Start Chapter Download", systemImage: "arrow.down")
            }.disabled(item.chapter.downloaded || operation != nil)
            
            Button(role: .destructive) {
                vm.deleteChapter(item.chapter)
            } label: {
                Label("Remove Chapter Download", systemImage: "trash.fill")
            }.disabled(!item.chapter.downloaded)
        }
    }
}

private struct ChapterDownloadButton: View {
    @EnvironmentObject private var vm: DetailsViewModel
    @ObservedObject private var queue = QueueProvider.shared
    let chapter: Chapter
    let operationId: String
    
    private let size: CGFloat = 20
    
    var operation: QueueOperation? {
        queue.operations[operationId]
    }
    
    // Computed properties for state
    private var isChapterDownloaded: Bool {
        chapter.downloaded
    }
    
    private var isDownloading: Bool {
        guard let op = operation else { return false }
        
        switch op.state {
        case .ongoing, .pending:
            return true
        default:
            return false
        }
    }
    
    private var downloadProgress: Double {
        operation?.progress ?? 0.0
    }
    
    private var downloadFailed: Bool {
        if let op = operation, case .failed = op.state {
            return true
        }
        return false
    }
    
    var body: some View {
        ZStack {
            if !isChapterDownloaded {
                // Progress circle background
                Circle()
                    .stroke(lineWidth: 2)
                    .opacity(downloadProgress > 0 ? 0.3 : 0)
                    .foregroundColor(.gray)
                
                // Progress circle
                Circle()
                    .trim(from: 0.0, to: downloadProgress)
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.accentColor)
                    .rotationEffect(Angle(degrees: 270.0))
                    .opacity(downloadProgress > 0 ? 1 : 0)
                
                // Download/Cancel button
                Button {
                    if isDownloading, let op = operation {
                        op.cancel()
                    } else {
                        vm.downloadChapter(chapter)
                    }
                } label: {
                    Image(systemName: isDownloading ? "arrowtriangle.down.circle" : "arrow.down.circle.fill")
                        .font(.system(size: size))
                        .foregroundStyle(Color.accentColor)
                        .opacity(downloadFailed ? 0 : 1)
                }
                
                // Failed state
                if downloadFailed {
                    Button {
                        vm.downloadChapter(chapter)
                    } label: {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: size))
                            .foregroundStyle(.red)
                    }
                }
            } else {
                // Completed state
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size))
                    .foregroundStyle(.green)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut, value: isChapterDownloaded)
        .animation(.spring(response: 0.3), value: downloadProgress)
    }
}

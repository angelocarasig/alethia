//
//  ChapterListView.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import SwiftUI
import Kingfisher

struct ChapterListView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
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
                    ChapterRow(item: chapter)
                        .id("\(chapter.chapter.title)-\(chapter.chapter.progress)")
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ChapterHeaderView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var targetChapter: ChapterExtended? {
        vm.details?.chapters
            .sorted { $0.chapter.number < $1.chapter.number }
            .first(where: { !$0.chapter.read })
    }
    
    var targetChapterIndex: Int? {
        guard let targetChapter = targetChapter else { return nil }
        return vm.details?.chapters.firstIndex(of: targetChapter)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text("Chapters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("^[\(vm.chapters.count) chapter](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                NavigationLink {
                    if let chapter = targetChapter {
                        ReaderScreen(
                            mangaId: vm.details?.manga.id ?? -1,
                            mangaTitle: vm.details?.manga.title ?? "Unknown Title",
                            orientation: vm.resolvedOrientation ?? .LeftToRight,
                            currentChapter: chapter,
                            chapters: vm.details?.chapters ?? []
                        )
                    }
                    else {
                        EmptyView()
                    }
                } label: {
                    // Use the same logic as ContinueReadingView
                    if let chapter = targetChapter, let index = targetChapterIndex {
                        Text(index == (vm.details?.chapters.count ?? 0) - 1 ? "Start Reading" : "Continue Reading")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("All Chapters Read")
                            .font(.headline)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .disabled(targetChapter == nil)
                .buttonStyle(.borderedProminent)
                
                NavigationLink {
                    
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.text)
                        .frame(width: 44, height: 44)
                        .background(Color.tint)
                        .clipShape(.rect(cornerRadius: Constants.Corner.Radius.regular))
                }
            }
            .frame(height: 44)
        }
    }
}

private struct ChapterRow: View {
    @EnvironmentObject private var vm: DetailsViewModel
    let item: ChapterExtended
    
    var read: Bool {
        item.chapter.progress >= 1.0
    }
    
    var body: some View {
        HStack(spacing: Constants.Spacing.minimal) {
            KFImage(URL(fileURLWithPath: item.source?.icon ?? ""))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(
                    width: 50,
                    height: 50
                )
                .cornerRadius(Constants.Corner.Radius.regular)
                .padding(.trailing, Constants.Padding.regular)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                HStack {
                    Text("Chapter \(item.chapter.number.toString())")
                    Text("•").foregroundColor(.secondary)
                    Text(item.chapter.date.toRelativeString()).foregroundColor(.secondary)
                    
                    if item.chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
                        Text("NEW")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, Constants.Padding.minimal)
                            .padding(.horizontal, Constants.Padding.regular)
                            .background(Color.appRed)
                            .cornerRadius(Constants.Corner.Radius.regular)
                    }
                    
                    if read {
                        Text("Read")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, Constants.Padding.minimal)
                            .padding(.horizontal, Constants.Padding.regular)
                            .background(Color.appOrange)
                            .cornerRadius(Constants.Corner.Radius.regular)
                    }
                }
                .font(.subheadline)
                
                Text(item.chapter.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(item.scanlator.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if item.chapter.progress > 0 && item.chapter.progress != 1 {
                    Spacer()
                    
                    ProgressView(value: item.chapter.progress)
                        .tint(Color.accentColor)
                        .frame(height: 3)
                        .clipShape(Capsule())
                        .opacity(item.chapter.progress > 0.0 ? 1.0 : 0.0)
                }
            }
            Spacer()
            DownloadButton()
        }
        .padding(.vertical, Constants.Padding.minimal)
        .overlay {
            if read {
                ZStack(alignment: .topTrailing) {
                    Color.background.opacity(0.3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .allowsHitTesting(false) // pass through to next hittable element
            }
        }
        .contentShape(.rect)
        .contextMenu {
            ContextMenu()
        }
    }
    
    @ViewBuilder
    private func DownloadButton() -> some View {
        Text("DL")
    }
    
    @ViewBuilder
    private func ContextMenu() -> some View {
        ControlGroup {
            Button {
                vm.markChapter(asRead: true, for: item)
            } label: {
                Label("Mark Read", systemImage: "book.closed")
            }
            .disabled(item.chapter.read)
            
            Button {
                
            } label: {
                Label("Read Above", systemImage: "arrow.up.square.fill")
            }
            
            Button {
                
            } label: {
                Label("Read Below", systemImage: "arrow.down.square.fill")
            }
        }
        
        ControlGroup {
            Button {
                vm.markChapter(asRead: false, for: item)
            } label: {
                Label("Mark Unread", systemImage: "book")
            }
            .disabled(!item.chapter.read)
            
            Button {
                
            } label: {
                Label("Unread Above", systemImage: "arrow.up.square")
            }
            
            Button {
                
            } label: {
                Label("Unread Below", systemImage: "arrow.down.square")
            }
        }
        
        ControlGroup {
            Button {
            } label: {
                Label("Start Chapter Download", systemImage: "arrow.down")
            }
            .disabled(item.chapter.downloaded)
            
            Button(role: .destructive) {
            } label: {
                Label("Remove Chapter Download", systemImage: "trash.fill")
            }
            .disabled(!item.chapter.downloaded)
        }
    }
}

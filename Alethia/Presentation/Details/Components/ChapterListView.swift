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
    
    var details: Detail {
        vm.details.unsafelyUnwrapped
    }
    
    var body: some View {
        LazyVStack {
            ChapterHeaderView()
            
            ForEach(Array(details.chapters.enumerated()), id: \.element.chapter.id) {
                index,
                chapter in
                NavigationLink(
                    destination: ReaderScreen(
                        title: vm.details.unsafelyUnwrapped.manga.title,
                        orientation: vm.details.unsafelyUnwrapped.manga.orientation,
                        chapters: vm.details.unsafelyUnwrapped.chapters,
                        currentChapterIndex: index
                    )
                ) {
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
    
    var details: Detail {
        vm.details.unsafelyUnwrapped
    }
    
    var targetChapter: ChapterExtended? {
        details.chapters
            .sorted { $0.chapter.number < $1.chapter.number }
            .first(where: { !$0.chapter.read })
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapters")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(details.chapters.count) chapters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                SortButton()
            }
            
            HStack {
                NavigationLink {
                    if let chapter = targetChapter, let index = vm.details?.chapters.firstIndex(of: chapter) {
                        ReaderScreen(
                            title: vm.details.unsafelyUnwrapped.manga.title,
                            orientation: vm.details.unsafelyUnwrapped.manga.orientation,
                            chapters: vm.details.unsafelyUnwrapped.chapters,
                            currentChapterIndex: index
                        )
                    }
                    else {
                        EmptyView()
                    }
                    
                } label: {
                    Text("Continue Reading")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .disabled(false)
                .buttonStyle(.borderedProminent)
                
                NavigationLink {
                    
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.text)
                        .frame(width: 44, height: 44)
                        .background(Color.tint)
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
            .frame(height: 44)
        }
    }
    
    @ViewBuilder
    private func SortButton() -> some View {
        Menu {
            Section {
                //                ForEach(ChapterSortOption.allCases, id: \.rawValue) { option in
                //                    Button(action: {
                //                        vm.toggleSortOption(context: modelContext, option: option)
                //                    }) {
                //                        HStack {
                //                            Text(option.rawValue)
                //                                .foregroundColor(.primary)
                //                            Spacer()
                //                            if settings.sortOption == option {
                //                                Image(systemName: settings.sortDirection == .descending ? "arrow.down" : "arrow.up")
                //                                    .foregroundColor(.accentColor)
                //                            }
                //                        }
                //                    }
                //                }
            } header: {
                Text("Sort Chapters")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        } label: {
            CircleButton(icon: "line.3.horizontal.decrease", isActive: false)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct CircleButton: View {
    let icon: String
    var isActive: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    buttonContent
                }
            } else {
                buttonContent
            }
        }
    }
    
    private var buttonContent: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(isActive ? Color.accentColor : Color.tint)
            .foregroundStyle(.text)
            .clipShape(Circle())
            .contentShape(Circle())
    }
}

private struct ChapterRow: View {
    let item: ChapterExtended
    
    var read: Bool {
        item.chapter.progress >= 1.0
    }
    
    private let iconSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 8) {
            KFImage(URL(fileURLWithPath: item.source?.icon ?? ""))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(8)
                .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Chapter \(item.chapter.number.toString())")
                    Text("•").foregroundColor(.secondary)
                    Text(item.chapter.date.toRelativeString()).foregroundColor(.secondary)
                    
                    if item.chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
                        Text("NEW")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.appRed)
                            .cornerRadius(8)
                    }
                    
                    if read {
                        Text("Read")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(Color.appOrange)
                            .cornerRadius(8)
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
        .padding(.vertical, 6)
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
        Text("CTX")
        //        Group {
        //            ControlGroup {
        //                Button {
        //                } label: {
        //                    Label("Mark Read", systemImage: "book.closed")
        //                }
        //                .disabled(read)
        //
        //                Button {
        //
        //                } label: {
        //                    Label("Read Above", systemImage: "arrow.up.square.fill")
        //                }
        //
        //                Button {
        //
        //                } label: {
        //                    Label("Read Below", systemImage: "arrow.down.square.fill")
        //                }
        //            }
        //
        //            ControlGroup {
        //                Button {
        //                } label: {
        //                    Label("Mark Unread", systemImage: "book")
        //                }
        //                .disabled(!chapter.read)
        //
        //                Button {
        //
        //                } label: {
        //                    Label("Unread Above", systemImage: "arrow.up.square")
        //                }
        //
        //                Button {
        //
        //                } label: {
        //                    Label("Unread Below", systemImage: "arrow.down.square")
        //                }
        //            }
        //
        //            ControlGroup {
        //                Button {
        //                } label: {
        //                    Label("Start Chapter Download", systemImage: "arrow.down")
        //                }
        //                .disabled(chapter.isDownloaded)
        //
        //                Button(role: .destructive) {
        //                } label: {
        //                    Label("Remove Chapter Download", systemImage: "trash.fill")
        //                }
        //                .disabled(!chapter.isDownloaded)
        //            }
        //        }
    }
}

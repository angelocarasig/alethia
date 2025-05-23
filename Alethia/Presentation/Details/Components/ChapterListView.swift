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
                        orientation: vm.details?.manga.orientation ?? .LeftToRight,
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
        vm.chapters
            .sorted { $0.chapter.number < $1.chapter.number }
            .first(where: { !$0.chapter.read })
    }
    
    var targetChapterIndex: Int? {
        guard let targetChapter = targetChapter else { return nil }
        return vm.details?.chapters.firstIndex(of: targetChapter)
    }
    
    var body: some View {
        VStack(spacing: Constants.Spacing.large) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                    Text("Chapters")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("^[\(vm.chapters.count) chapter](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                SortButton()
            }
            
            HStack {
                NavigationLink {
                    if let chapter = targetChapter {
                        ReaderScreen(
                            mangaId: vm.details?.manga.id ?? -1,
                            mangaTitle: vm.details?.manga.title ?? "Unknown Title",
                            orientation: vm.details?.manga.orientation ?? .LeftToRight,
                            currentChapter: chapter,
                            chapters: vm.details?.chapters ?? []
                        )
                    }
                    else {
                        Text("Empty View!")
                        EmptyView()
                    }
                } label: {
                    Text(targetChapter != nil ? "Continue Reading" : "All Chapters Read")
                        .font(.headline)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .frame(
                width: Constants.Icon.Size.regular,
                height: Constants.Icon.Size.regular
            )
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

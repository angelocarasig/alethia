//
//  ChapterListView.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import SwiftUI
import NukeUI

struct ChapterListView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail {
        vm.details!
    }
    
    var body: some View {
        LazyVStack {
            ChapterHeaderView()
            
            ForEach(details.chapters) { chapter in
                ChapterRow(chapter: chapter)
            }
        }
    }
}

private struct ChapterHeaderView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail {
        vm.details!
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
    let chapter: Chapter
    
    var read: Bool {
        chapter.progress >= 1.0
    }
    
    private let iconSize: CGFloat = 40
    
    var body: some View {
        HStack(spacing: 10) {
            LazyImage(url: URL(fileURLWithPath: "")) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                        .cornerRadius(12)
                }
                else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tint)
                        .frame(width: iconSize, height: iconSize)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Chapter \(chapter.number.toString())")
                    Text("•").foregroundColor(.secondary)
                    Text(chapter.date.toRelativeString()).foregroundColor(.secondary)
                    
                    if chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
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
                
                Text(chapter.title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .font(.headline)
                    .fontWeight(.semibold)
                
//                Text(chapter.scanlator)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
                
                if chapter.progress > 0 && chapter.progress != 1 {
                    Spacer()
                    
                    ProgressView(value: chapter.progress)
                        .tint(Color.accentColor)
                        .frame(height: 3)
                        .clipShape(Capsule())
                        .opacity(chapter.progress > 0.0 ? 1.0 : 0.0)
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

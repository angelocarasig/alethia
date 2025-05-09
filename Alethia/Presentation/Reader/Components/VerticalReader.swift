//
//  VerticalReaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 8/5/2025.
//

import SwiftUI
import SwiftUIIntrospect

struct VerticalReader: View {
    @EnvironmentObject private var vm: ReaderViewModel
    
    @State private var scrollViewRef: UIScrollView?
    @State private var scrollPosition: String?
    @State private var anchorIDBeforeInsert: String?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(vm.pages) { page in
                        let correspondingChapter = vm.chapters[page.chapterIndex]
                        
                        if page.isFirstPage {
                            PreviousChapter(
                                chapter: correspondingChapter,
                                onWillLoadPrevious: { onWillLoadPrevious(page: page) },
                                onDidLoadPrevious: { onDidLoadPrevious(proxy: proxy) }
                            )
                            .id("transition-previous-\(page.id)")
                        }
                        
                        RetryableImage(
                            url: page.url,
                            index: page.id,
                            referer: page.getReferer(chapters: vm.chapters)
                        )
                        .onAppear { vm.currentPage = page }
                        .id("page-\(page.id)")
                        
                        if page.isLastPage {
                            NextChapter(chapter: correspondingChapter)
                                .id("transition-next-\(page.id)")
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .introspect(.scrollView, on: .iOS(.v17, .v18)) { scrollView in
                DispatchQueue.main.async {
                    scrollViewRef = scrollView
                }
            }
            .scrollPosition(id: $scrollPosition)
            .scrollDisabled(anchorIDBeforeInsert != nil)
        }
    }
    
    private func onWillLoadPrevious(page: Page) {
        anchorIDBeforeInsert = "transition-previous-\(page.id)"
        
        if let scrollView = scrollViewRef {
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            scrollView.isScrollEnabled = false // disable for now while loading
        }
    }
    
    private func onDidLoadPrevious(proxy: ScrollViewProxy) {
        if let scrollView = scrollViewRef {
            scrollView.isScrollEnabled = true
        }
        
        if let id = anchorIDBeforeInsert {
            withAnimation { @MainActor in
                proxy.scrollTo(id, anchor: .top)
                anchorIDBeforeInsert = nil
            }
        }
    }
}

private struct PreviousChapter: View {
    // Track Y-Offset for loading previous chapter
    private struct ViewOffsetKey: PreferenceKey {
        static var defaultValue: CGFloat = .infinity
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = min(value, nextValue())
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    // Once triggered it shouldn't be called again
    @State private var hasTriggeredLoad: Lock = .unlocked
    
    let chapter: ChapterExtended
    var onWillLoadPrevious: (() -> Void)? = nil
    var onDidLoadPrevious: (() -> Void)? = nil
    
    var chapterIndex: Int? {
        vm.chapters.firstIndex(where: { $0.chapter.id == chapter.chapter.id })
    }
    
    var previousChapter: ChapterExtended? {
        guard let index = chapterIndex, index + 1 < vm.chapters.count else {
            return nil
        }
        return vm.chapters[index + 1]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(chapter.chapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let previousChapter = previousChapter, let index = chapterIndex {
                Button {
                    Task {
                        print("Manual Load: Loading Previous Chapter")
                        await vm.loadChapter(at: index + 1)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Previous Chapter")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(previousChapter.chapter.toString())
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Published by: \(previousChapter.scanlator.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.tint.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text("There is no previous chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ViewOffsetKey.self, value: geo.frame(in: .global).minY)
            }
        )
        .onPreferenceChange(ViewOffsetKey.self) { offset in
            print("Offset: \(offset)")
            if offset > 50, !hasTriggeredLoad, let index = chapterIndex {
                hasTriggeredLoad = .locked
                
                onWillLoadPrevious?() // track position in scrollview
                Task {
                    try? await withThrowingTimeout(seconds: 1) {
                        print("Loading Chapter from PREV")
                        await vm.loadChapter(at: index + 1)
                        onDidLoadPrevious?() // restore position since content has been loaded in
                    }
                }
            }
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

private struct NextChapter: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    let chapter: ChapterExtended
    
    var chapterIndex: Int? {
        vm.chapters.firstIndex(where: { $0.chapter.id == chapter.chapter.id })
    }
    
    var nextChapter: ChapterExtended? {
        guard let index = chapterIndex, index - 1 >= 0 else {
            return nil
        }
        return vm.chapters[index - 1]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 8) {
                Text(chapter.chapter.toString())
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Currently Reading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let nextChapter = nextChapter, let index = chapterIndex {
                Button {
                    Task {
                        print("Loading Chapter from NEXT")
                        await vm.loadChapter(at: index - 1)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Chapter")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(nextChapter.chapter.toString())
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                
                                Text("Published by: \(nextChapter.scanlator.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear {
                    Task {
                        try? await withThrowingTimeout(seconds: 1) {
                            print("Loading Chapter from NEXT")
                            await vm.loadChapter(at: index - 1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.tint.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text("There is no next chapter.")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}


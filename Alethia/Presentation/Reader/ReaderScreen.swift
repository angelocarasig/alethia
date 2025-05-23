//
//  ReaderScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 22/5/2025.
//

import SwiftUI
import Kingfisher

struct ReaderScreen: View {
    @StateObject private var vm: ReaderViewModel
    
    @State private var scrollPosition = ScrollPosition(idType: Page.ID.self)
    
    init(
        mangaTitle: String,
        orientation: Orientation,
        currentChapter: ChapterExtended,
        chapters: [ChapterExtended]
    ) {
        self._vm = StateObject(
            wrappedValue: ReaderViewModel(
                mangaTitle: mangaTitle,
                orientation: orientation,
                currentChapter: currentChapter,
                chapters: chapters
            )
        )
    }
    
    var body: some View {
        VStack {
            switch vm.state {
            case .idle, .loading:
                LoadingView()
            case .loaded(let pages):
                ContentView(pages: pages)
            case .error(let error):
                ContentUnavailableView(
                    error.localizedDescription,
                    systemImage: "exclamationmark.triangle.fill"
                )
            }
        }
        .onTapGesture { vm.toggleControls() }
        .overlay(ReaderOverlay())
        .toolbar(.hidden, for: .tabBar)     // tab bar
        .navigationBarBackButtonHidden()    // navigation bar (i.e. back dismiss())
        .statusBarHidden(!vm.showControls)  // statusbar (i.e. battery, wifi etc.)
        .edgesIgnoringSafeArea(.vertical)   // make it infinite
        .task { await vm.loadChapter() }
        .environmentObject(vm)
    }
    
    @ViewBuilder
    private func ContentView(pages: [Page]) -> some View {
        if vm.orientation.isVertical {
            VerticalReader(pages)
        }
        else if vm.orientation.isHorizontal {
            HorizontalReader(pages)
        }
        else {
            ContentUnavailableView("Something went wrong.", systemImage: "exclamationmark.triangle.fill")
        }
    }
}

// MARK: Readers

extension ReaderScreen {
    @ViewBuilder
    private func HorizontalReader(_ pages: [Page]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(pages) { page in
                    RetryableImage(
                        url: page.pageUrl,
                        referer: page.pageReferer
                    )
                    .id(page.pageNumber)
                    .onAppear { vm.updateCurrentPage(page: page) }
                    .containerRelativeFrame(
                        .horizontal,
                        count: 1,
                        spacing: 0
                    )
                }
                .scrollTargetLayout()
                
                EndDetails()
                    .onAppear { vm.endDetailsVisible = true }
                    .onDisappear { vm.endDetailsVisible = false }
            }
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition($scrollPosition)
        .if(vm.orientation == .RightToLeft) { view in
            view
                .environment(\.layoutDirection, .rightToLeft)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .onChange(of: vm.orientation) {
            scrollPosition.scrollTo(edge: .top)
        }
        .onChange(of: vm.currentPage) {
            guard vm.didScrollScrubber else { return }
            
            withAnimation(.none) {
                scrollPosition.scrollTo(id: vm.currentPage?.pageNumber, anchor: .top)
            }
            
            vm.didScrollScrubber = false
        }
    }
    
    @ViewBuilder
    private func VerticalReader(_ pages: [Page]) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(pages) { page in
                    RetryableImage(
                        url: page.pageUrl,
                        referer: page.pageReferer
                    )
                    .id(page.pageNumber)
                    .onAppear { vm.updateCurrentPage(page: page) }
                    .containerRelativeFrame(
                        vm.orientation == Orientation.Vertical ? .vertical : .horizontal,
                        count: 1,
                        spacing: 0
                    )
                }
                .scrollTargetLayout()
                
                EndDetails()
                    .onAppear { vm.endDetailsVisible = true }
                    .onDisappear { vm.endDetailsVisible = false }
            }
        }
        .if(vm.orientation == Orientation.Vertical) { view in
            // a 'vertical' reader is still paginated
            view.scrollTargetBehavior(.paging)
        }
        .scrollPosition($scrollPosition)
        .onChange(of: vm.orientation) {
            scrollPosition.scrollTo(edge: .top)
        }
        .onChange(of: vm.currentPage) {
            guard vm.didScrollScrubber else { return }
            
            withAnimation(.none) {
                scrollPosition.scrollTo(id: vm.currentPage?.pageNumber, anchor: .top)
            }
            
            vm.didScrollScrubber = false
        }
    }
}

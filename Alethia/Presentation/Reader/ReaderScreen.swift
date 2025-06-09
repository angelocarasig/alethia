//
//  ReaderScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 22/5/2025.
//

import SwiftUI
import Kingfisher

struct ReaderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ReaderViewModel
    
    @State private var scrollPosition = ScrollPosition(idType: Page.ID.self)
    
    init(
        mangaId: Int64,
        mangaTitle: String,
        orientation: Orientation,
        currentChapter: ChapterExtended,
        chapters: [ChapterExtended]
    ) {
        self._vm = StateObject(
            wrappedValue: ReaderViewModel(
                mangaId: mangaId,
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
                ContentUnavailableView {
                    Label("Something went wrong.", systemImage: "exclamationmark.triangle.fill")
                } description: {
                    Text(error.localizedDescription)
                        .padding()
                } actions: {
                    Button {
                        Task {
                            await vm.loadChapter()
                        }
                    } label: {
                        Text("Retry")
                            .fontWeight(.semibold)
                            .padding(.horizontal, Constants.Padding.regular)
                            .padding(.vertical, Constants.Padding.minimal)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Exit")
                            .fontWeight(.semibold)
                            .padding(.horizontal, Constants.Padding.regular)
                            .padding(.vertical, Constants.Padding.minimal)
                    }
                }
            }
        }
        .gesture(
            TapGesture()
                .onEnded { _ in
                    vm.toggleControls()
                }
                .exclusively(before: TapGesture(count: 2)) // some cooking
        )
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
                    .onScrollVisibilityChange { isVisible in
                        if !vm.didScrollScrubber && isVisible {
                            vm.updateCurrentPage(page: page)
                        }
                    }
                    .containerRelativeFrame(
                        .horizontal,
                        count: 1,
                        spacing: 0
                    )
                }
                .scrollTargetLayout()
                .zoomable()
                
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
        .onChange(of: vm.currentChapter) {
            scrollPosition.scrollTo(edge: .top)
        }
        .onChange(of: vm.orientation) {
            scrollPosition.scrollTo(edge: .top)
        }
        .onChange(of: vm.currentPage) {
            guard vm.didScrollScrubber else { return }
            
            withAnimation(.none) {
                scrollPosition.scrollTo(id: vm.currentPage?.pageNumber ?? 1, anchor: .top)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                vm.didScrollScrubber = false
            }
        }
        .onScrollPhaseChange { _, newPhase in
            vm.isScrolling = newPhase != .idle
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
                    // onappear easier for vertical reader here
                    .onAppear {
                        if !vm.didScrollScrubber {
                            vm.updateCurrentPage(page: page)
                        }
                    }
                    .id(page.pageNumber)
                    .containerRelativeFrame(
                        vm.orientation == Orientation.Vertical ? .vertical : .horizontal,
                        count: 1,
                        spacing: 0
                    )
                }
                .scrollTargetLayout()
                // apply zoomable to vstack when vertical
                .if(vm.orientation == Orientation.Vertical) { view in
                    view.zoomable()
                }
                
                EndDetails()
                    .onAppear { vm.endDetailsVisible = true }
                    .onDisappear { vm.endDetailsVisible = false }
            }
        }
        .if(vm.orientation == Orientation.Vertical) { view in
            // a 'vertical' reader is still paginated
            view.scrollTargetBehavior(.paging)
        }
        .if(vm.orientation == Orientation.Infinite) { view in
            // if its infinite we need to apply it to the entire scrollview
            // while not end details isn't visible this should be zoomable
            view.zoomable(isZoomable: !vm.endDetailsVisible)
        }
        .scrollPosition($scrollPosition)
        .onChange(of: vm.currentChapter) {
            withAnimation(.none) {
                scrollPosition.scrollTo(edge: .top)
            }
        }
        .onChange(of: vm.orientation) {
            withAnimation(.none) {
                scrollPosition.scrollTo(edge: .top)
            }
        }
        .onChange(of: vm.currentPage) {
            guard vm.didScrollScrubber else { return }
            
            withAnimation(.none) {
                scrollPosition.scrollTo(id: vm.currentPage?.pageNumber ?? 1, anchor: .top)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                vm.didScrollScrubber = false
            }
        }
        .onScrollPhaseChange { _, newPhase in
            vm.isScrolling = newPhase != .idle
        }
    }
}

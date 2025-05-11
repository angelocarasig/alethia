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
                // used for scrolling to top
                Color.clear.id("top")
                
                LazyVStack(spacing: 0) {
                    ForEach(vm.pages) { page in
                        let correspondingChapter = page.getUnderlyingChapter(chapters: vm.chapters)
                        
                        if page.isFirstPage {
                            VerticalChapterTransition(
                                direction: .previous,
                                chapter: correspondingChapter,
                                onWillLoad: { onWillLoad(page: page, isPrevious: true) },
                                onDidLoad: { onDidLoad(proxy: proxy) }
                            )
                            .id("transition-previous-\(page.id)")
                        }
                        
                        RetryableImage(
                            url: page.url,
                            index: page.id,
                            referer: correspondingChapter.origin.referer
                        )
                        .containerRelativeFrame(
                            vm.orientation == Orientation.Vertical ? .vertical : .horizontal,
                            count: 1,
                            spacing: 0
                        )
                        .onAppear { vm.currentPage = page }
                        .id("page-\(page.id)")
                        
                        if page.isLastPage {
                            VerticalChapterTransition(
                                direction: .next,
                                chapter: correspondingChapter,
                                onWillLoad: { onWillLoad(page: page, isPrevious: false) },
                                onDidLoad: { onDidLoad(proxy: proxy) }
                            )
                            .id("transition-next-\(page.id)")
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .if(vm.orientation == Orientation.Vertical) { view in
                view
                    .defaultScrollAnchor(.center)
                    .scrollTargetBehavior(.paging)
            }
            .onChange(of: vm.orientation) {
                proxy.scrollTo("top")
            }
            .onChange(of: vm.currentPage) {
                onSliderScroll(proxy: proxy)
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
    
    private func onWillLoad(page: Page, isPrevious: Bool) {
        if isPrevious {
            anchorIDBeforeInsert = "transition-previous-\(page.id)"
        }
        else {
            anchorIDBeforeInsert = "transition-next-\(page.id)"
        }
        
        if let scrollView = scrollViewRef {
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            scrollView.isScrollEnabled = false // disable for now while loading
        }
    }
    
    private func onDidLoad(proxy: ScrollViewProxy) {
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
    
    private func onSliderScroll(proxy: ScrollViewProxy) -> Void {
        guard vm.scrolledFromSlider else { return }
        proxy.scrollTo("page-\(vm.currentPage?.id ?? "")", anchor: .top)
        vm.scrolledFromSlider = false
    }
}

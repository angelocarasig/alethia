//
//  Reader.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import UIKit
import SwiftUI
import AsyncDisplayKit
import ChatLayout
import Kingfisher

/// main reader view controller that handles infinite scrolling manga reading
final class Reader: UIViewController {
    
    // MARK: - Properties
    
    let collectionView: UICollectionView
    var chatLayout: CollectionViewChatLayout
    var flowLayout: UICollectionViewFlowLayout?
    let dataSource: AnyReaderDataSource
    private(set) var configuration: ReaderConfiguration
    let chapterManager: ChapterManager
    let pageMapper: PageMapper
    let scrollHandler: ReaderScrollHandler
    let ordering: AnyChapterOrdering
    
    var currentChapterId: ChapterID
    var cachedImageURLs: [String] = []
    var imageSizes: [String: CGSize] = [:]
    
    // page tracking
    var visiblePages: Set<Int> = []
    var currentPage: Int = 0
    
    var currentChapter: AnyReadableChapter? {
        dataSource.chapters.first { $0.id == currentChapterId }
    }
    
    var currentChapterPageCount: Int {
        return pageMapper.getCurrentChapterPageCount(for: currentChapterId)
    }
    
    // zoom tracking
    var isAnyPageZoomed: Bool = false
    
    // scroll state tracking
    var isUserScrolling: Bool = false
    var isProgrammaticScroll: Bool = false
    
    // callbacks
    var onPageChange: (@MainActor @Sendable (Int, AnyReadableChapter) -> Void)?
    var onChapterChange: (@MainActor @Sendable (AnyReadableChapter) -> Void)?
    var onScrollStateChange: (@MainActor @Sendable (Bool) -> Void)?
    var onError: (@MainActor @Sendable (Error) -> Void)?
    
    // MARK: - Initialization
    
    init(
        dataSource: AnyReaderDataSource,
        startingChapterId: ChapterID,
        ordering: AnyChapterOrdering,
        configuration: ReaderConfiguration = .default
    ) {
        self.dataSource = dataSource
        self.currentChapterId = startingChapterId
        self.ordering = ordering
        self.configuration = configuration
        
        self.chapterManager = ChapterManager(
            chapters: dataSource.chapters,
            fetchPages: { chapterId in
                try await dataSource.fetchPages(for: chapterId)
            }
        )
        
        self.pageMapper = PageMapper()
        self.scrollHandler = ReaderScrollHandler()
        
        // setup layout based on reading mode
        if configuration.readingMode == .leftToRight || configuration.readingMode == .rightToLeft {
            let flow = UICollectionViewFlowLayout()
            flow.scrollDirection = .horizontal
            flow.minimumLineSpacing = 0
            flow.minimumInteritemSpacing = 0
            self.flowLayout = flow
            self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)
            self.chatLayout = CollectionViewChatLayout()
        } else {
            let layout = CollectionViewChatLayout()
            layout.settings.interItemSpacing = 0
            layout.settings.additionalInsets = .zero
            self.chatLayout = layout
            self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadInitialChapter()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: { _ in
            // reset to page 0 of current chapter
            self.currentPage = 0
            
            // trigger callbacks to update UI (scrollbar, etc.)
            if let chapter = self.currentChapter {
                self.onPageChange?(0, chapter)
            }
            
            // update visible pages to ensure state is synced
            DispatchQueue.main.async {
                self.updateVisiblePages()
            }
        })
    }
    
    // MARK: - Internal API
    
    func jumpToPage(_ page: Int, in chapterId: ChapterID, animated: Bool) {
        guard let globalIndex = pageMapper.getGlobalIndex(for: chapterId, page: page) else { return }
        
        isProgrammaticScroll = true
        
        let indexPath = IndexPath(item: globalIndex, section: 0)
        
        // get layout attributes for target cell
        if let layoutAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
            var targetRect = layoutAttributes.frame
            
            // adjust rect based on reading mode to anchor at top-left
            switch configuration.readingMode {
            case .leftToRight, .rightToLeft:
                targetRect.origin.x = layoutAttributes.frame.minX
                targetRect.origin.y = 0
                targetRect.size = collectionView.bounds.size
                
            case .infinite, .vertical:
                targetRect.origin.x = 0
                targetRect.origin.y = layoutAttributes.frame.minY
                targetRect.size = collectionView.bounds.size
            }
            
            collectionView.scrollRectToVisible(targetRect, animated: animated)
        } else {
            // fallback to scrollToItem if layout attributes unavailable
            let scrollPosition: UICollectionView.ScrollPosition
            switch configuration.readingMode {
            case .leftToRight, .rightToLeft:
                scrollPosition = .left
            case .infinite, .vertical:
                scrollPosition = .top
            }
            
            collectionView.scrollToItem(
                at: indexPath,
                at: scrollPosition,
                animated: animated
            )
        }
        
        // if not animated, reset flag immediately
        if !animated {
            isProgrammaticScroll = false
        }
    }
    
    func jumpToChapter(_ chapterId: ChapterID, animated: Bool) {
        jumpToPage(0, in: chapterId, animated: animated)
    }
    
    func nextChapter() {
        let navigation = getNavigation(for: currentChapterId)
        guard let next = navigation.next else { return }
        
        Task {
            let isLoaded = await chapterManager.isChapterLoaded(next.id)
            if !isLoaded {
                await loadChapter(next.id, position: .next)
            }
            
            await MainActor.run {
                jumpToChapter(next.id, animated: true)
            }
        }
    }
    
    func previousChapter() {
        let navigation = getNavigation(for: currentChapterId)
        guard let previous = navigation.previous else { return }
        
        Task {
            let isLoaded = await chapterManager.isChapterLoaded(previous.id)
            if !isLoaded {
                await loadChapter(previous.id, position: .previous)
            }
            
            await MainActor.run {
                jumpToChapter(previous.id, animated: true)
            }
        }
    }
    
    func updateConfiguration(_ newConfiguration: ReaderConfiguration) {
        // only update if configuration actually changed
        guard configuration != newConfiguration else { return }
        
        let oldMode = configuration.readingMode
        let newMode = newConfiguration.readingMode
        
        configuration = newConfiguration
        
        // if mode changed, reconfigure layout
        if oldMode != newMode {
            let currentChapterIdToPreserve = currentChapterId
            
            // switch layout if needed
            let needsFlowLayout = (newMode == .leftToRight || newMode == .rightToLeft)
            let hasFlowLayout = (flowLayout != nil)
            
            if needsFlowLayout && !hasFlowLayout {
                let flow = UICollectionViewFlowLayout()
                flow.scrollDirection = .horizontal
                flow.minimumLineSpacing = 0
                flow.minimumInteritemSpacing = 0
                flowLayout = flow
                collectionView.collectionViewLayout = flow
                collectionView.isPagingEnabled = true
            } else if !needsFlowLayout && hasFlowLayout {
                chatLayout.settings.interItemSpacing = 0
                chatLayout.settings.additionalInsets = .zero
                collectionView.collectionViewLayout = chatLayout
                collectionView.isPagingEnabled = (newMode == .vertical)
                flowLayout = nil
            } else {
                collectionView.isPagingEnabled = (newMode == .vertical || newMode == .leftToRight || newMode == .rightToLeft)
            }
            
            collectionView.semanticContentAttribute = (newMode == .rightToLeft) ? .forceRightToLeft : .forceLeftToRight
            
            Task {
                await updateCachedData()
                
                await MainActor.run {
                    collectionView.reloadData()
                    
                    // scroll to first page of current chapter
                    if let firstPageIndex = pageMapper.getGlobalIndex(for: currentChapterIdToPreserve, page: 0) {
                        let scrollPosition: UICollectionView.ScrollPosition = needsFlowLayout ? .left : .top
                        collectionView.scrollToItem(
                            at: IndexPath(item: firstPageIndex, section: 0),
                            at: scrollPosition,
                            animated: false
                        )
                    }
                    
                    // reset internal state and trigger callbacks
                    self.currentPage = 0
                    if let chapter = self.currentChapter {
                        self.onPageChange?(0, chapter)
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    func getNavigation(for chapterId: ChapterID) -> (next: AnyReadableChapter?, previous: AnyReadableChapter?) {
        switch ordering {
        case .index:
            guard let currentIndex = dataSource.chapters.firstIndex(where: { $0.id == chapterId }) else {
                return (next: nil, previous: nil)
            }
            let next = dataSource.chapters.indices.contains(currentIndex + 1) ? dataSource.chapters[currentIndex + 1] : nil
            let previous = dataSource.chapters.indices.contains(currentIndex - 1) ? dataSource.chapters[currentIndex - 1] : nil
            return (next: next, previous: previous)
            
        case .custom(let navigationClosure):
            return navigationClosure(chapterId, dataSource.chapters)
        }
    }
    
    // MARK: - Setup
    
    private func setupCollectionView() {
        collectionView.backgroundColor = configuration.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.isPrefetchingEnabled = true
        collectionView.showsVerticalScrollIndicator = configuration.showsScrollIndicator
        collectionView.showsHorizontalScrollIndicator = configuration.showsScrollIndicator
        collectionView.isPagingEnabled = (configuration.readingMode == .vertical || configuration.readingMode == .leftToRight || configuration.readingMode == .rightToLeft)
        collectionView.semanticContentAttribute = (configuration.readingMode == .rightToLeft) ? .forceRightToLeft : .forceLeftToRight
        
        if configuration.readingMode != .leftToRight && configuration.readingMode != .rightToLeft {
            chatLayout.delegate = self
        }
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadInitialChapter() {
        Task {
            await loadChapter(currentChapterId, position: .initial)
        }
    }
    
    func updateCachedData() async {
        let loadedChapters = await chapterManager.getLoadedChapters()
        let orderedChapterIds = await chapterManager.getLoadedChapterIds()
        cachedImageURLs = await chapterManager.allImageURLs(orderedBy: orderedChapterIds)
        pageMapper.updateMapping(chapters: loadedChapters, orderedBy: orderedChapterIds)
    }
}

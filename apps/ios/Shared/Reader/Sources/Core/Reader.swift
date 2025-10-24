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
    
    // new components for improved behavior
    let stateMachine: ReaderStateMachine
    let insertionStrategy: InsertionStrategy
    let callbackManager: CallbackManager
    
    // chapter insertion task tracking
    var insertionTask: Task<Void, Never>?
    var insertionTaskId: UUID?
    
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
    
    // pending state for initial load (like Suwatte)
    var pendingState: (chapterId: ChapterID, page: Int)?
    var isLoaded: Bool = false
    
    // callbacks (now managed through CallbackManager)
    var onPageChange: (@MainActor @Sendable (Int, AnyReadableChapter) -> Void)? {
        didSet {
            callbackManager.onPageChange = { [weak self] context in
                guard let self = self,
                      let chapter = self.dataSource.chapters.first(where: { $0.id == context.chapterId }) else { return }
                self.onPageChange?(context.page, chapter)
            }
        }
    }
    
    var onChapterChange: (@MainActor @Sendable (AnyReadableChapter) -> Void)? {
        didSet {
            callbackManager.onChapterChange = { [weak self] context in
                guard let self = self,
                      let chapter = self.dataSource.chapters.first(where: { $0.id == context.chapterId }) else { return }
                self.onChapterChange?(chapter)
            }
        }
    }
    
    var onScrollStateChange: (@MainActor @Sendable (Bool) -> Void)? {
        didSet {
            callbackManager.onScrollStateChange = onScrollStateChange
        }
    }
    
    var onError: (@MainActor @Sendable (Error) -> Void)? {
        didSet {
            callbackManager.onError = onError
        }
    }
    
    var onChapterLoadComplete: (@MainActor @Sendable (ChapterID, Int) -> Void)? {
        didSet {
            callbackManager.onChapterLoadComplete = onChapterLoadComplete
        }
    }
    
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
        self.stateMachine = ReaderStateMachine()
        self.insertionStrategy = InsertionStrategy()
        self.callbackManager = CallbackManager()
        
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
        
        setupStateMachine()
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
        
        // capture anchor before rotation
        let anchor = insertionStrategy.captureAnchor(
            from: collectionView,
            pageMapper: pageMapper,
            readingMode: configuration.readingMode
        )
        
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: { _ in
            // restore anchor after rotation
            if let anchor = anchor,
               let newIndex = self.pageMapper.getGlobalIndex(for: anchor.chapterId, page: anchor.pageInChapter) {
                let indexPath = IndexPath(item: newIndex, section: 0)
                
                switch self.configuration.readingMode {
                case .leftToRight, .rightToLeft:
                    self.collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
                case .infinite, .vertical:
                    self.collectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                }
            }
            
            // update visible pages to ensure state is synced
            DispatchQueue.main.async {
                self.updateVisiblePages(reason: .programmaticJump)
            }
        })
    }
    
    // MARK: - State Machine Setup
    
    private func setupStateMachine() {
        stateMachine.onStateChange { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .error(let error):
                self.callbackManager.emitError(error)
            case .ready:
                // ensure we emit current position when becoming ready
                if self.isLoaded {
                    self.updateVisiblePages(reason: .programmaticJump)
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Internal API
    
    func jumpToPage(_ page: Int, in chapterId: ChapterID, animated: Bool) {
        guard let globalIndex = pageMapper.getGlobalIndex(for: chapterId, page: page) else { return }
        
        isProgrammaticScroll = true
        
        Task {
            await callbackManager.suppressDuring(reason: .programmaticJump) {
                await MainActor.run {
                    let indexPath = IndexPath(item: globalIndex, section: 0)
                    
                    // get layout attributes for target cell
                    if let layoutAttributes = self.collectionView.layoutAttributesForItem(at: indexPath) {
                        var targetRect = layoutAttributes.frame
                        
                        // adjust rect based on reading mode to anchor at top-left
                        switch self.configuration.readingMode {
                        case .leftToRight, .rightToLeft:
                            targetRect.origin.x = layoutAttributes.frame.minX
                            targetRect.origin.y = 0
                            targetRect.size = self.collectionView.bounds.size
                            
                        case .infinite, .vertical:
                            targetRect.origin.x = 0
                            targetRect.origin.y = layoutAttributes.frame.minY
                            targetRect.size = self.collectionView.bounds.size
                        }
                        
                        self.collectionView.scrollRectToVisible(targetRect, animated: animated)
                    } else {
                        // fallback to scrollToItem if layout attributes unavailable
                        let scrollPosition: UICollectionView.ScrollPosition
                        switch self.configuration.readingMode {
                        case .leftToRight, .rightToLeft:
                            scrollPosition = .left
                        case .infinite, .vertical:
                            scrollPosition = .top
                        }
                        
                        self.collectionView.scrollToItem(
                            at: indexPath,
                            at: scrollPosition,
                            animated: animated
                        )
                    }
                }
            }
            
            // if not animated, reset flag immediately
            if !animated {
                await MainActor.run {
                    self.isProgrammaticScroll = false
                    self.updateVisiblePages(reason: .programmaticJump)
                }
            }
        }
    }
    
    func jumpToChapter(_ chapterId: ChapterID, animated: Bool) {
        jumpToPage(0, in: chapterId, animated: animated)
    }
    
    func nextChapter() {
        guard stateMachine.canStartLoading else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        guard let next = navigation.next else { return }
        
        Task {
            let isLoaded = await chapterManager.isChapterLoaded(next.id)
            if !isLoaded {
                _ = stateMachine.transition(to: .loadingNext)
                await loadChapter(next.id, position: .next)
            }
            
            await MainActor.run {
                jumpToChapter(next.id, animated: true)
            }
        }
    }
    
    func previousChapter() {
        guard stateMachine.canStartLoading else { return }
        
        let navigation = getNavigation(for: currentChapterId)
        guard let previous = navigation.previous else { return }
        
        Task {
            let isLoaded = await chapterManager.isChapterLoaded(previous.id)
            if !isLoaded {
                _ = stateMachine.transition(to: .loadingPrevious)
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
            let currentPageToPreserve = currentPage
            
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
                    self.collectionView.reloadData()
                    
                    // scroll to preserved page
                    if let firstPageIndex = self.pageMapper.getGlobalIndex(for: currentChapterIdToPreserve, page: currentPageToPreserve) {
                        let scrollPosition: UICollectionView.ScrollPosition = needsFlowLayout ? .left : .top
                        self.collectionView.scrollToItem(
                            at: IndexPath(item: firstPageIndex, section: 0),
                            at: scrollPosition,
                            animated: false
                        )
                    }
                    
                    // trigger callbacks with new state
                    self.updateVisiblePages(reason: .programmaticJump)
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
        // set pending state
        pendingState = (chapterId: currentChapterId, page: 0)
        
        _ = stateMachine.transition(to: .loadingInitial)
        
        Task {
            await loadChapter(currentChapterId, position: .initial)
        }
    }
    
    func updateCachedData() async {
        // get all image URLs in proper chapter order
        cachedImageURLs = await chapterManager.getAllImageURLsInOrder()
        
        // rebuild the page mapper with proper order
        let loadedChapters = await chapterManager.getLoadedChapters()
        
        // sort loaded chapters by their position in the original chapter list
        let sortedChapters = loadedChapters.sorted { chapter1, chapter2 in
            guard let index1 = dataSource.chapters.firstIndex(where: { $0.id == chapter1.id }),
                  let index2 = dataSource.chapters.firstIndex(where: { $0.id == chapter2.id }) else {
                return false
            }
            return index1 < index2
        }
        
        let sortedIds = sortedChapters.map { $0.id }
        pageMapper.updateMapping(chapters: sortedChapters, orderedBy: sortedIds)
        
        print("[Reader] Updated cached data: \(cachedImageURLs.count) total images, \(sortedChapters.count) chapters")
    }
}

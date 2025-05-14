//
//  VerticalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/5/2025.
//

final class VerticalReader: UIView {
    // MARK: - Properties
    private var startChapter: Chapter
    private var chapters: [Chapter]
    private var pages: [Page] = []
    private var currentChapterIndex: Int
    private var visiblePages: [Int: Page] = [:]
    
    // Reader orientation mode
    private var orientation: Orientation
    
    // Track last visited chapter to detect changes
    private var lastVisitedChapter: Chapter?
    
    // Track preloaded chapters to avoid duplicate loading
    private var preloadedChapterIds: Set<Int64> = []
    
    // Flag to track loading state
    private var isLoadingChapter = false
    
    // Flag to trace whether we're in the middle of a chapter transition
    private var isTransitioningChapters = false
    
    // Cache image dimensions
    private var imageHeightCache = NSCache<NSString, NSNumber>()
    
    private var collectionView: UICollectionView!
    private let cellReuseIdentifier = "PageCell"
    
    weak var delegate: VerticalReaderDelegate?
    
    // MARK: - Initialization
    init(startChapter: Chapter, chapters: [Chapter], orientation: Orientation) {
        self.startChapter = startChapter
        self.chapters = chapters
        self.currentChapterIndex = chapters.firstIndex(where: { $0.id == startChapter.id }) ?? 0
        self.lastVisitedChapter = startChapter
        self.orientation = orientation
        
        // Reset tracking sets for clean navigation
        self.preloadedChapterIds = []
        self.isLoadingChapter = false
        self.isTransitioningChapters = false
        
        super.init(frame: .zero)
        
        setupCollectionView()
        loadInitialPages()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        // Use custom flow layout to ensure proper cell sizing
        let layout = NoSpacingFlowLayout()
        layout.scrollDirection = .Vertical
        layout.orientation = self.orientation  // Pass the orientation to our custom layout
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        
        // Configure based on orientation mode
        switch orientation {
        case .Infinite:
            // Continuous scrolling mode
            collectionView.isPagingEnabled = false
            collectionView.decelerationRate = .normal
            collectionView.alwaysBounceVertical = true
        case .Vertical:
            // True pagination mode - one image per screen
            // Don't use built-in paging as we need custom page sizes
            collectionView.isPagingEnabled = false
            // Make pages snap into place with faster deceleration
            collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
            // Disable bounce for precise page changes
            collectionView.alwaysBounceVertical = false
        case .LeftToRight, .RightToLeft:
            // Will be implemented later
            break
        }
        
        // Common settings for both modes
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        
        // Eliminate any extra spacing
        collectionView.contentInset = .zero
        
        collectionView.register(PageCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Page Loading
    private func loadInitialPages() {
        // Force load the initial chapter even if it's in the preloaded set
        loadPagesForChapter(startChapter, isInitialLoad: true)
        collectionView.reloadData()
    }
    
    private func loadPagesForChapter(_ chapter: Chapter, isInitialLoad: Bool = false) {
        // Guard against invalid chapter
        guard let chapterId = chapter.id else {
            print("Warning: Invalid chapter")
            return
        }
        
        // When NOT initial load, check loading state
        if !isInitialLoad && isLoadingChapter {
            print("Already loading a chapter, skipping")
            return
        }
        
        // For preloaded chapters, only skip if this isn't the initial load
        if !isInitialLoad && preloadedChapterIds.contains(chapterId) {
            print("Chapter \(chapter.number) already in preloaded set, skipping content loading")
            return
        }
        
        // Mark as loading
        isLoadingChapter = true
        
        // Mark this chapter as preloaded
        preloadedChapterIds.insert(chapterId)
        
        let chapterPages = getChapterContents(chapter: chapter, chapters: chapters)
        
        // Ensure we have pages to add
        guard !chapterPages.isEmpty else {
            print("Warning: No pages found for chapter \(chapter.number)")
            isLoadingChapter = false
            return
        }
        
        print("Successfully loaded \(chapterPages.count) pages for chapter \(chapter.number)")
        
        // Update collection data first
        if pages.isEmpty {
            pages = chapterPages
        } else {
            // If we're appending to the end
            pages.append(contentsOf: chapterPages)
        }
        
        // Then preload image dimensions (after data is available)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for page in chapterPages {
                self?.preloadImage(for: page.url)
            }
            
            DispatchQueue.main.async {
                self?.isLoadingChapter = false
            }
        }
    }
    
    private func preloadImage(for urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        KingfisherManager.shared.retrieveImage(with: url, options: [.backgroundDecode]) { [weak self] result in
            if case .success(let imageResult) = result {
                let image = imageResult.image
                let screenWidth = UIScreen.main.bounds.width
                let aspectRatio = image.size.height / image.size.width
                let height = screenWidth * aspectRatio
                
                self?.imageHeightCache.setObject(NSNumber(value: Float(height)), forKey: urlString as NSString)
                
                DispatchQueue.main.async {
                    // Only invalidate layout for Infinite scrolling
                    if let orientation = self?.orientation, orientation == .Infinite {
                        self?.collectionView.performBatchUpdates({
                            self?.collectionView.collectionViewLayout.invalidateLayout()
                        }, completion: { _ in
                            // Force another layout pass to ensure cells use updated heights
                            self?.collectionView.layoutIfNeeded()
                        })
                    }
                }
            }
        }
    }
    
    private func loadPreviousChapter() {
        // Guard against invalid states
        guard 
            !chapters.isEmpty,
            currentChapterIndex > 0,
            !isLoadingChapter
        else { 
            return 
        }
        
        // Set loading flag
        isLoadingChapter = true
        
        currentChapterIndex -= 1
        let previousChapter = chapters[currentChapterIndex]
        
        // Skip if already preloaded
        if let previousChapterId = previousChapter.id, preloadedChapterIds.contains(previousChapterId) {
            print("Chapter \(previousChapter.number) already preloaded, skipping")
            isLoadingChapter = false
            return
        }
        
        // Add to preloaded set
        if let previousChapterId = previousChapter.id {
            preloadedChapterIds.insert(previousChapterId)
        }
        
        print("Loading previous chapter: \(previousChapter.number)")
        let previousPages = getChapterContents(chapter: previousChapter, chapters: chapters)
        
        // Then preload images in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for page in previousPages {
                self?.preloadImage(for: page.url)
            }
        }
        
        pages.insert(contentsOf: previousPages, at: 0)
        
        // Reload collection view on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                return 
            }
            
            // Keep scroll position
            let oldContentOffset = self.collectionView.contentOffset
            self.collectionView.reloadData()
            let newOffset = CGPoint(
                x: oldContentOffset.x, 
                y: oldContentOffset.y + self.collectionView.contentSize.height - oldContentOffset.y
            )
            self.collectionView.contentOffset = newOffset
            self.isLoadingChapter = false
        }
    }
    
    private func loadNextChapter() {
        // Guard against invalid states
        guard 
            !chapters.isEmpty,
            currentChapterIndex < chapters.count - 1,
            !isLoadingChapter
        else { 
            return 
        }
        
        // Set loading flag
        isLoadingChapter = true
        
        currentChapterIndex += 1
        let nextChapter = chapters[currentChapterIndex]
        
        // Skip if already preloaded
        if let nextChapterId = nextChapter.id, preloadedChapterIds.contains(nextChapterId) {
            print("Chapter \(nextChapter.number) already preloaded, skipping")
            isLoadingChapter = false
            return
        }
        
        // Add to preloaded set
        if let nextChapterId = nextChapter.id {
            preloadedChapterIds.insert(nextChapterId)
        }
        
        print("Loading next chapter: \(nextChapter.number)")
        loadPagesForChapter(nextChapter, isInitialLoad: false)
        
        // Reload collection view on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.collectionView.reloadData()
            self.isLoadingChapter = false
        }
    }
    
    // MARK: - Utility Methods
    func scrollToPage(at index: Int, animated: Bool = true) {
        guard index >= 0 && index < pages.count else { return }
        
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
    }
    
    private func getEstimatedHeight(for urlString: String) -> CGFloat {
        if let cachedHeight = imageHeightCache.object(forKey: urlString as NSString) {
            return CGFloat(cachedHeight.floatValue)
        }
        // Default height
        return UIScreen.main.bounds.width * 1.5
    }
}

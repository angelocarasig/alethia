//
//  +Controller.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit
import Combine
import AsyncDisplayKit

final class VerticalReaderController: ASDKViewController<ASCollectionNode> {
    let vm: ReaderViewModel
    var dataSource = VerticalReaderDataSource()
    let dataCache = ReaderDataCache()
    
    // Positioning
    var lastIndexPath: IndexPath = .init(item: 0, section: 0)
    var resumptionPosition: (Int, CGFloat)?
    
    // Scroll
    var currentChapterRange: (min: CGFloat, max: CGFloat) = (min: .zero, max: .zero)
    var didTriggerBackTick = false
    var lastKnownScrollPosition: CGFloat = 0.0
    var lastStoppedScrollPosition: CGFloat = 0.0
    var scrollPositionUpdateThreshold: CGFloat = 30.0
    
    // Others
    var subscriptions = Set<AnyCancellable>()
    var hasCompletedInitialLoad: Bool = false
    
    init(vm: ReaderViewModel) {
        self.vm = vm
        let layout = VerticalLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        super.init(node: node)
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        if !hasCompletedInitialLoad {
            startup() // uses detached async
            subscribeAll()
            return
        }
    }
    
    func presentNode() {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: [.transitionCrossDissolve, .allowUserInteraction])
        {
            self.collectionNode.alpha = 1
        }
    }
}


// MARK: Computed

extension VerticalReaderController {
    var collectionNode: ASCollectionNode {
        return node
    }
    
    var contentSize: CGSize {
        collectionNode.collectionViewLayout.collectionViewContentSize
    }
    
    var offset: CGFloat {
        collectionNode.contentOffset.y
    }
    
    var currentPoint: CGPoint {
        collectionNode.view.currentPoint
    }
    
    var currentPath: IndexPath? {
        collectionNode.view.pathAtCenterOfScreen
    }
    
    var pathAtCenterOfScreen: IndexPath? {
        collectionNode.view.pathAtCenterOfScreen
    }
}

// MARK: Functions
extension VerticalReaderController {
    func setup() {
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.shouldAnimateSizeChanges = false
        collectionNode.backgroundColor = .clear
        collectionNode.insetsLayoutMarginsFromSafeArea = false
        collectionNode.alpha = 0
        collectionNode.automaticallyManagesSubnodes = true
        
        // TODO: Zoom delegate
//        navigationController?.delegate = zoomTransitionDelegate
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
        
        collectionNode.isPagingEnabled = false
        collectionNode.showsVerticalScrollIndicator = false
        collectionNode.showsHorizontalScrollIndicator = false
        
        // TODO: Add Gestures
        // addGestures()
        collectionNode.view.contentInsetAdjustmentBehavior = .never
        collectionNode.view.scrollsToTop = false
    }
    
    func clearResumption() {
        resumptionPosition = nil
    }
}

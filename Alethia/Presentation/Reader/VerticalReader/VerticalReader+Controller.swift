//
//  VerticalReader+Controller.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit
import Combine
import AsyncDisplayKit

final class VerticalReaderController: ASDKViewController<ASCollectionNode> {
    var vm: ReaderViewModel
    var dataSource: DataSource
    
    var resumptionPosition: (Int, CGFloat)? = (0, 0.0)
    
    init(vm: ReaderViewModel) {
        self.vm = vm
        self.dataSource = DataSource(vm: vm)
        
        let layout = VerticalLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        
        super.init(node: node)
        
        node.delegate = self
        node.dataSource = self
        node.backgroundColor = .systemBackground
        node.view.alwaysBounceVertical = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        vm.cancellables.removeAll()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
}

// MARK: Lifecycle
extension VerticalReaderController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNode()
        setupBindings()
        startup()
    }
    
    private func setupNode() {
        // Configure collection node
        node.allowsSelection = false
        node.view.showsVerticalScrollIndicator = true
        node.view.contentInsetAdjustmentBehavior = .never
    }
}

// MARK: Logic
extension VerticalReaderController {
    func startup() {
        Task { [weak self] in
            guard let self else { return }
            await self.initialLoad()
        }
    }
    
    func initialLoad() async {
        switch vm.state {
        case .placeholder:
            await vm.loadInitialChapter(vm.startingChapter)
        default:
            return
        }
    }
    
    func clearResumption() {
        resumptionPosition = nil
    }
}

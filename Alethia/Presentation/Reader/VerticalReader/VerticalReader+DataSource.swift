//
//  VerticalReader+DataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import AsyncDisplayKit

// MARK: DataSource
/// Essentially acts as an adapter, MVVM -> UIKit is strange
struct DataSource {
    let vm: ReaderViewModel
    
    func itemIdentifier(for path: IndexPath) -> ReaderPanel? {
        guard path.section < vm.sections.count else { return nil }
        let sectionSlug = vm.sections[path.section]
        
        guard let panelState = vm.loadedChapters[sectionSlug],
              case .loaded = panelState.state,
              let panels = panelState.panels,
              path.item < panels.count else {
            return nil
        }
        
        return panels[path.item]
    }
    
    func numberOfItems(in section: Int) -> Int {
        guard section < vm.sections.count else { return 0 }
        let sectionSlug = vm.sections[section]
        
        guard let panelState = vm.loadedChapters[sectionSlug],
              case .loaded = panelState.state,
              let panels = panelState.panels else {
            return 0
        }
        
        return panels.count
    }
}

// MARK: DEBUG {
extension VerticalReaderController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("View appeared - collection view frame: \(node.view.frame)")
        print("Collection view contentSize: \(node.view.contentSize)")
        print("Collection view is hidden: \(node.isHidden)")
        print("Collection view bounds: \(node.view.bounds)")
    }
    
    
}

// MARK: ASCollectionDataSource
extension VerticalReaderController: ASCollectionDataSource {
    /// Returns number of distinct chapters (aka sections) to display
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return vm.sections.count
    }
    
    /// Returns number of panels to display for the chapter (aka section) -> chapter page panels + 2 transition panels
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        // First, check if the section index is valid
        guard section < vm.sections.count else {
            return 0
        }
        
        // Get the slug at that index position
        let slug: Slug = vm.sections[section]
        
        // Check if the chapter is loaded and has panels
        guard let panelState: ReaderPanelState = vm.loadedChapters[slug],
              case .loaded = panelState.state,
              let panels: [ReaderPanel] = panelState.panels else {
            return 0
        }
        
        return panels.count
    }
    
    /// Creates collection node based on panel type
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return { [weak self] in
            guard let self = self,
                  let panel = self.dataSource.itemIdentifier(for: indexPath) else {
                return ASCellNode()
            }
            
            return self.createCellNode(for: panel)
        }
    }
    
    /// Perform preload for given collection node `onAppear` if page is below threshold
    func collectionNode(_: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        guard let path = node.indexPath else { return }
        guard let panel = dataSource.itemIdentifier(for: path) else { return }
        
        // Only check pages, not transitions
        guard case let .page(page) = panel else { return }
        
        // Check if we're near the end of the chapter
        let current = page.pageNumber
        let count = page.pageCount
        let inPreloadRange = count - current < 5
        
        if inPreloadRange {
            Task { [weak self] in
                await self?.vm.preloadChapter(after: page.underlyingChapter)
                await self?.buildChapterIfLoaded(for: page.underlyingChapter, direction: .next)
            }
        }
    }
    
    func buildChapterIfLoaded(for chapter: ChapterExtended, direction: ChapterLoadType) async {
        print("Curernt Sections: \(vm.sections)")
        guard
            // find node were working with
            let node: ReaderChapterListNode = vm.chapters.findNode(where: { $0.chapter.slug == chapter.chapter.slug }),
            let next: ReaderChapterListNode = node.next,
            // chapter should be loaded
            vm.hasLoadedChapter(next.chapter),
            // already inserted sections should not contain it
            !vm.sections.contains(next.chapter.chapter.slug)
        else { return }
        
        let slug = next.chapter.chapter.slug
        
        // Make sure we have valid panels
        guard let panelState = vm.loadedChapters[slug],
              case .loaded = panelState.state,
              let panels = panelState.panels
        else { return }
        
        // Update view model's sections
        vm.updateSection(for: slug, at: direction)
        
        // Calculate section index and paths for batch update
        let sectionIndex = direction == .previous ? 0 : vm.sections.count - 1
        let paths = panels.indices.map { IndexPath(item: $0, section: sectionIndex) }
        let set = IndexSet(integer: sectionIndex)
        
        // If inserting at the head, prepare layout
        if direction == .previous {
            prepareForInsertAtHead()
        }
        
        // Perform batch update
        await collectionNode.performBatch(animated: false) { [weak self] in
            self?.collectionNode.insertSections(set)
            self?.collectionNode.insertItems(at: paths)
        }
    }
    
    private func prepareForInsertAtHead() {
        let layout = node.collectionViewLayout as? VerticalLayout
        layout?.isInsertingCellsToTop = true
    }
    
    private func createCellNode(for panel: ReaderPanel) -> ASCellNode {
        switch panel {
        case .page(let page):
            return VerticalImageNode(page: page, delegate: self)
        case .transition(let transition):
            return VerticalTransitionNode(transition: transition, delegate: self)
        }
    }
}

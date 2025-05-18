//
//  VerticalReader+DataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import SwiftUI
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
    
    /// Perform preload for given collection node `onAppear` if page is below threshold or if it's a transition
    func collectionNode(_: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        guard let path = node.indexPath else { return }
        guard let panel = dataSource.itemIdentifier(for: path) else { return }
        
        switch panel {
        case let .page(page):
            // Check if we're near the end of the chapter
            let current = page.pageNumber
            let count = page.pageCount
            let inNextPreloadRange = abs(count - current) < Constants.Reader.PreloadChapterPanelThreshold
            let inPrevPreloadRange = current < Constants.Reader.PreloadChapterPanelThreshold
            
            if inNextPreloadRange {
                Task { [weak self] in
                    await self?.vm.preloadChapter(after: page.underlyingChapter)
                    await self?.buildChapterIfLoaded(for: page.underlyingChapter, direction: .next)
                }
            }
            else if inPrevPreloadRange {
                Task { [weak self] in
                    await self?.vm.preloadChapter(before: page.underlyingChapter)
                    await self?.buildChapterIfLoaded(for: page.underlyingChapter, direction: .previous)
                }
            }
            
        case let .transition(transition):
            // For transitions, preload based on the transition direction
            Task { [weak self] in
                switch transition.direction {
                case .previous:
                    // If it's a "previous chapter" transition, preload the previous chapter
                    await self?.vm.preloadChapter(before: transition.from)
                    await self?.buildChapterIfLoaded(for: transition.from, direction: .previous)
                    
                case .update:
                    fallthrough
                case .next:
                    // If it's a "next chapter" transition, preload the next chapter
                    await self?.vm.preloadChapter(after: transition.from)
                    await self?.buildChapterIfLoaded(for: transition.from, direction: .next)
                }
            }
        }
    }
    
    func buildChapterIfLoaded(for chapter: ChapterExtended, direction: ChapterLoadType) async {
        print("Current Sections: \(vm.sections)")
        
        // Find the node for the provided chapter
        guard let node = vm.chapters.findNode(where: { $0.chapter.slug == chapter.chapter.slug }) else {
            print("Node not found for chapter: \(chapter.chapter.slug)")
            return
        }
        
        // Determine which adjacent chapter to load based on direction
        let adjacentNode: ReaderChapterListNode?
        switch direction {
        case .previous:
            adjacentNode = node.prev
        case .next:
            adjacentNode = node.next
        case .update:
            adjacentNode = nil
        }
        
        // Make sure adjacent node exists and is loaded
        guard let adjacentNode = adjacentNode,
              vm.hasLoadedChapter(adjacentNode.chapter),
              !vm.sections.contains(adjacentNode.chapter.chapter.slug) else {
            print("Adjacent node not valid or already loaded: \(adjacentNode?.chapter.chapter.slug ?? "nil")")
            return
        }
        
        let slug = adjacentNode.chapter.chapter.slug
        
        // Make sure we have valid panels
        guard let panelState = vm.loadedChapters[slug],
              case .loaded = panelState.state,
              let panels = panelState.panels else {
            print("No valid panels for slug: \(slug)")
            return
        }
        
        // Update the view model's sections
        vm.updateSection(for: slug, at: direction)
        
        // Calculate section index and paths for batch update
        let sectionIndex = direction == .previous ? 0 : vm.sections.count - 1
        let paths = panels.indices.map { IndexPath(item: $0, section: sectionIndex) }
        let set = IndexSet(integer: sectionIndex)
        
        // If inserting at the head, prepare layout
        if direction == .previous {
            await MainActor.run {
                prepareForInsertAtHead()
            }
            
            // Perform batch update right after setting the flag
            await collectionNode.performBatch(animated: false) { [weak self] in
                guard let self = self else { return }
                self.collectionNode.insertSections(set)
                self.collectionNode.insertItems(at: paths)
            }
        } else {
            // For other directions, just perform the batch update normally
            await collectionNode.performBatch(animated: false) { [weak self] in
                self?.collectionNode.insertSections(set)
                self?.collectionNode.insertItems(at: paths)
            }
        }
    }
    
    private func prepareForInsertAtHead() {
        let layout = collectionNode.view.collectionViewLayout as? VerticalLayout
        layout?.isInsertingCellsToTop = true
    }
    
    private func createCellNode(for panel: ReaderPanel) -> ASCellNode {
        switch panel {
        case .page(let page):
            let node = ASCellNode(viewControllerBlock: {
                let view = RetryableImage(url: page.url,
                                          index: page.id,
                                          referer: page.referer)
                return UIHostingController(rootView: view)
            })
            return node
            
        case .transition(let transition):
            let node = ASCellNode(viewControllerBlock: {
                let view = VerticalChapterTransition(transition: transition)
                return UIHostingController(rootView: view)
            })
            node.style.height = ASDimension(unit: .points, value: 300)
            return node
        }
    }
}

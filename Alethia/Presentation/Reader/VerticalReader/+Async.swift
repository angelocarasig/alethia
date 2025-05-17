//
//  +Async.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit
import AsyncDisplayKit

extension VerticalReaderController {
    func collectionNode(_: ASCollectionNode, willDisplayItemWith node: ASCellNode) {
        let path = node.indexPath
        guard let path else { return }
        
        guard let data = dataSource.itemIdentifier(for: path) else { return }
        
        guard case let .page(target) = data else { return }
        
        // check if page range is below threshold
        let threshold: Int = abs(target.totalPages - target.pageNumber)
        
        guard threshold < Constants.Reader.PreloadRange else { return }
        
        Task { [weak self] in
            await self?.preload(after: target.chapter)
        }
    }
    
    func preload(after chapter: Chapter) async {
        guard
            // next chapter should exist
            let next: ChapterExtended = vm.chapters.nextChapter(for: chapter.slug),
            // chapter should not already be in sections (if in, its either loading or already loaded)
            vm.loadedState[next.chapter.slug] == nil
        else { return }
        
        await loadChapter(next)
    }
}

extension VerticalReaderController {
    func startup() {
        Task { [weak self] in
            guard let self else { return }
            await dataCache.setChapters(vm.chapters.getAllChapters())
            await self.initialLoad()
        }
    }
    
    func initialLoad() async {
        guard let pendingState = vm.pendingState else {
            return
        }
        let chapter = pendingState.chapter
        let isLoaded = vm.loadedState[chapter.id] != nil
        
        if let index = pendingState.pageIndex, let offset = pendingState.pageOffset {
            resumptionPosition = (index, offset)
        }
        
        if !isLoaded {
            await loadChapter(chapter)
        } else {
            // Data has already been loaded, just apply instead
            await apply(chapter)
        }
        
        // Retrieve chapter data
        guard let chapterIndex = await dataCache.chapters.firstIndex(of: chapter) else {
            print("load complete but page list is empty", "ImageViewer")
            return
        }
        
        guard let page = await dataCache.get(chapter.id)?.getOrNil(pendingState.pageIndex ?? 0) else {
            print("Unable to get the requested page or the first page in the chapter", "WebtoonController")
            return
        }
        
        vm.updateViewerStateChapter(chapter)
        vm.updateViewerState(with: page)
        
        let isFirstChapter = chapterIndex == 0
        let requestedPageIndex = (pendingState.pageIndex ?? 0) + (isFirstChapter ? 1 : 0)
        let indexPath = IndexPath(item: requestedPageIndex, section: 0)
        await MainActor.run {
            vm.clearPendingState() // Consume Pending State
            lastIndexPath = indexPath
            collectionNode.scrollToItem(at: indexPath, at: .top, animated: false)
            
            // TODO: For when I add overlay
//            updateChapterScrollRange()
//            setScrollPCT()
            presentNode()
            lastKnownScrollPosition = offset
            lastStoppedScrollPosition = offset
            hasCompletedInitialLoad = true
        }
    }
}

extension VerticalReaderController {
    func loadChapter(_ chapter: ChapterExtended) async {
        do {
            // update state to loading
            vm.updateChapterState(for: chapter, state: .loading)
            
            // fetch chapter contents
            let results = try await vm.getChapterContents(chapter: chapter)
            
            // update cache with new data
            await dataCache.update(chapter: chapter, pages: results)
            
            vm.updateChapterState(for: chapter, state: .loaded(true))
            
            await apply(chapter)
        }
        catch {
            vm.updateChapterState(for: chapter, state: .failed(error))
            return
        }
    }
    
    @MainActor
    func loadPreviousChapter() async {
        guard let current = pathAtCenterOfScreen, // Current index
              let panel: ReaderPanel = dataSource.itemIdentifier(for: current), // Current panel from index
              let chapter: ChapterExtended = vm.chapters.findChapter(where: { $0.chapter.slug == panel.chapter.slug }),
              let prev: ChapterExtended = await dataCache.previousChapter(for: chapter.chapter), // Prev Chapter in List
              vm.loadedState[prev.id] == nil  // is not already loading/loaded
        else { return }
        
        do {
            // Mark as loading
            vm.updateChapterState(for: prev, state: .loading)
            
            // Get layout before we start modifying content
            let layout = collectionNode.view.collectionViewLayout as? VerticalLayout
            
            // Tell layout we're going to insert content at the top
            layout?.isInsertingCellsToTop = true
            
            // Fetch content
            let results = try await vm.getChapterContents(chapter: prev)
            await dataCache.update(chapter: prev, pages: results)
            vm.updateChapterState(for: prev, state: .loaded(true))
            
            // Create panels
            let pages: [ReaderPanel] = await build(for: prev)
            
            // Add to data source at the beginning
            let id = prev.id // Use previous chapter ID
            dataSource.sections.insert(id, at: 0)
            dataSource.appendItems(pages, to: id)
            
            // Create paths for the new content
            let section = 0
            let paths = pages.indices.map { IndexPath(item: $0, section: section) }
            let set = IndexSet(integer: section)
            
            // Perform batch updates WITHOUT animation
            await collectionNode.performBatch(animated: false) { [weak self] in
                self?.collectionNode.insertSections(set)
                self?.collectionNode.insertItems(at: paths)
            }
            
            // The layout will automatically adjust the content offset in its prepare method
        }
        catch {
            vm.updateChapterState(for: prev, state: .failed(error))
            return
        }
    }
    
    // inserts collection node items for given chapter pages
    func apply(_ chapter: ChapterExtended) async {
        // retrieve readerpanels to add
        let pages: [ReaderPanel] = await build(for: chapter)
        
        let id: Slug = chapter.id
        dataSource.appendSections([id])
        dataSource.appendItems(pages, to: id)
        let section = dataSource.sections.count - 1
        let paths = pages.indices.map { IndexPath(item: $0, section: section) }
        let set = IndexSet(integer: section)
        await collectionNode.performBatch(animated: false) { [weak self] in
            self?.collectionNode.insertSections(set)
            self?.collectionNode.insertItems(at: paths)
        }
    }
    
    func build(for chapter: ChapterExtended) async -> [ReaderPanel] {
        await dataCache.prepare(chapter.chapter.slug) ?? []
    }
    
    func preparingToInsertAtHead() {
        let layout = collectionNode.view.collectionViewLayout as? OffsetPreservingLayout
        layout?.isInsertingCellsToTop = true
    }
}

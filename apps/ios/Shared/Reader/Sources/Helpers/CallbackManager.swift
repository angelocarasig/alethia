//
//  CallbackManager.swift
//  Reader
//
//  Created by Angelo Carasig on 24/10/2025.
//

import Foundation

/// manages debounced callbacks for stable UI updates
@MainActor
final class CallbackManager {
    
    /// callback context with reason
    struct CallbackContext {
        let chapterId: ChapterID
        let page: Int
        let totalPages: Int
        let reason: ChangeReason
    }
    
    // callback closures
    var onPageChange: ((CallbackContext) -> Void)?
    var onChapterChange: ((CallbackContext) -> Void)?
    var onScrollStateChange: ((Bool) -> Void)?
    var onError: ((Error) -> Void)?
    var onChapterLoadComplete: ((ChapterID, Int) -> Void)?
    
    // debouncing state
    private var pageDebounceTask: Task<Void, Never>?
    private var chapterDebounceTask: Task<Void, Never>?
    private let pageDebounceInterval: TimeInterval = 0.1
    private let chapterDebounceInterval: TimeInterval = 0.2
    
    // last emitted values to prevent duplicates
    private var lastEmittedPage: (chapterId: ChapterID, page: Int)?
    private var lastEmittedChapter: ChapterID?
    
    // suppression flags
    private var suppressCallbacks = false
    private var suppressReason: ChangeReason?
    
    /// suppress callbacks during an operation
    func suppressDuring(reason: ChangeReason, operation: () async -> Void) async {
        suppressCallbacks = true
        suppressReason = reason
        
        await operation()
        
        suppressCallbacks = false
        suppressReason = nil
    }
    
    /// emit page change with debouncing
    func emitPageChange(_ context: CallbackContext) {
        // don't emit if suppressed
        guard !suppressCallbacks else {
            print("[CallbackManager] Page change suppressed: \(context.page)")
            return
        }
        
        // don't emit duplicates
        if let last = lastEmittedPage,
           last.chapterId == context.chapterId && last.page == context.page {
            return
        }
        
        // cancel previous debounce
        pageDebounceTask?.cancel()
        
        // debounce based on reason
        let delay: TimeInterval = context.reason == .userScroll ? pageDebounceInterval : 0
        
        pageDebounceTask = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            guard !Task.isCancelled else { return }
            
            self.lastEmittedPage = (context.chapterId, context.page)
            self.onPageChange?(context)
            
            print("[CallbackManager] Emitted page change: \(context.page) (reason: \(context.reason))")
        }
    }
    
    /// emit chapter change with debouncing
    func emitChapterChange(_ context: CallbackContext) {
        // don't emit if suppressed
        guard !suppressCallbacks else {
            print("[CallbackManager] Chapter change suppressed")
            return
        }
        
        // don't emit duplicates
        if lastEmittedChapter == context.chapterId {
            return
        }
        
        // cancel previous debounce
        chapterDebounceTask?.cancel()
        
        // debounce based on reason
        let delay: TimeInterval = context.reason == .userScroll ? chapterDebounceInterval : 0
        
        chapterDebounceTask = Task {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            guard !Task.isCancelled else { return }
            
            self.lastEmittedChapter = context.chapterId
            self.onChapterChange?(context)
            
            print("[CallbackManager] Emitted chapter change: \(String(describing: context.chapterId)) (reason: \(context.reason))")
        }
    }
    
    /// emit scroll state change immediately
    func emitScrollStateChange(_ isScrolling: Bool) {
        onScrollStateChange?(isScrolling)
    }
    
    /// emit error immediately
    func emitError(_ error: Error) {
        onError?(error)
        print("[CallbackManager] Emitted error: \(error)")
    }
    
    /// emit chapter load complete immediately
    func emitChapterLoadComplete(chapterId: ChapterID, pageCount: Int) {
        onChapterLoadComplete?(chapterId, pageCount)
        print("[CallbackManager] Emitted chapter load complete: \(String(describing: chapterId)), \(pageCount) pages")
    }
    
    /// cancel all pending callbacks
    func cancelPendingCallbacks() {
        pageDebounceTask?.cancel()
        chapterDebounceTask?.cancel()
    }
    
    /// reset callback state
    func reset() {
        cancelPendingCallbacks()
        lastEmittedPage = nil
        lastEmittedChapter = nil
        suppressCallbacks = false
        suppressReason = nil
    }
}

//
//  QueueProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation
import Combine
import Collections

final class QueueProvider: ObservableObject {
    static var shared = QueueProvider()
    
    @Published var operations = OrderedDictionary<QueueOperationId, QueueOperation>()
    
    private var cancellables = Set<AnyCancellable>()
    private let downloadChapterUseCase: DownloadChapterUseCase
    private let metadataRefreshUseCase: RefreshMetadataUseCase
    
    private var throttleWorkItem: DispatchWorkItem?
    private let queueUpdateQueue = DispatchQueue(label: "queue.update", qos: .utility)
    
    private var lastMetadataRequestTime: Dictionary<String, Date> = .init()
    private let sourceThrottleInterval: TimeInterval = 3.0
    private let throttleQueue = DispatchQueue(label: "throttle.sync", attributes: .concurrent)
    
    private init() {
        let injector = DependencyInjector.shared
        self.downloadChapterUseCase = injector.makeDownloadChapterUseCase()
        self.metadataRefreshUseCase = injector.makeRefreshMetadataUseCase()
    }
}

// MARK: - Getters
extension QueueProvider {
    func getOperation(for id: QueueOperationId) -> QueueOperation? {
        return self.operations[id]
    }
}

// MARK: - Publishers
extension QueueProvider {
    func entryStatePublisher(entry: Entry) -> AnyPublisher<EntryQueueState, Never> {
        guard let mangaId = entry.mangaId else {
            return Just(.idle).eraseToAnyPublisher()
        }
        
        return $operations
            .map { operations in
                var state: EntryQueueState = []
                
                for operation in operations.values where operation.state.isActive && operation.mangaId == mangaId {
                    switch operation.type {
                    case .chapterDownload:
                        state.insert(.downloading)
                    case .metadataRefresh:
                        state.insert(.updatingMetadata)
                    }
                }
                
                return state
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Use-cases
extension QueueProvider {
    func downloadChapter(_ chapter: Chapter, mangaId: Int64?) {
        guard operations[chapter.queueOperationId]?.state.isFinished != false else {
            return
        }
        
        if let existingOperation = operations[chapter.queueOperationId],
           existingOperation.state.isFinished {
            operations.removeValue(forKey: chapter.queueOperationId)
        }
        
        let operation = QueueOperation(item: chapter, type: .chapterDownload(chapter), mangaId: mangaId)
        operations[chapter.queueOperationId] = operation
        
        operation.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        operation.publisher
            .sink { [weak self] state in
                switch state {
                case .completed, .failed, .cancelled:
                    self?.updateQueue()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        updateQueue()
    }
    
    func refreshMetadata(_ entry: Entry) {
        guard operations[entry.queueOperationId]?.state.isFinished != false else {
            return
        }
        
        // Check per-source throttling
        if let sourceId = entry.sourceId {
            let sourceKey = String(sourceId)
            let now = Date()
            
            let shouldThrottle = throttleQueue.sync {
                let lastRequest = lastMetadataRequestTime[sourceKey] ?? .distantPast
                return now.timeIntervalSince(lastRequest) < sourceThrottleInterval
            }
            
            guard !shouldThrottle else {
                return // Throttled for this source
            }
            
            throttleQueue.async(flags: .barrier) { [weak self] in
                self?.lastMetadataRequestTime[sourceKey] = now
            }
        }
        
        if let existingOperation = operations[entry.queueOperationId],
           existingOperation.state.isFinished {
            operations.removeValue(forKey: entry.queueOperationId)
        }
        
        let operation = QueueOperation(item: entry, type: .metadataRefresh(entry), mangaId: entry.mangaId)
        operations[entry.queueOperationId] = operation
        
        operation.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        operation.publisher
            .sink { [weak self] state in
                switch state {
                case .completed, .failed, .cancelled:
                    self?.updateQueue()
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        updateQueue()
    }
}

// MARK: - Internal
private extension QueueProvider {
    func updateQueue() {
        let ongoingCount = operations.values.filter {
            if case .ongoing = $0.state { return true }
            return false
        }.count
        
        // If we have slots available, process immediately
        if ongoingCount < Constants.Queue.ConcurrentOperationsCount {
            performQueueUpdate()
        }
        
        // Always set up throttled processing for overflow/future items
        throttleWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.performQueueUpdate()
        }
        
        throttleWorkItem = workItem
        queueUpdateQueue.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
    
    func performQueueUpdate() {
        let ongoingCount = operations.values.filter {
            if case .ongoing = $0.state { return true }
            return false
        }.count
        
        guard ongoingCount < Constants.Queue.ConcurrentOperationsCount else { return }
        
        let pendingOperations = operations.values.filter { $0.state == .pending }
        let slotsAvailable = Constants.Queue.ConcurrentOperationsCount - ongoingCount
        
        for operation in pendingOperations.prefix(slotsAvailable) {
            switch operation.type {
            case .chapterDownload(let chapter):
                let stream = downloadChapterUseCase.execute(chapter: chapter)
                operation.start(with: stream)
                
            case .metadataRefresh(let entry):
                let stream = metadataRefreshUseCase.execute(mangaId: entry.mangaId!)
                operation.start(with: stream)
            }
        }
    }
}

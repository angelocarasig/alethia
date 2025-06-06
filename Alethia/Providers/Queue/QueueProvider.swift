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
        // Check if operation doesn't exist OR if it exists but is finished
        guard operations[chapter.queueOperationId]?.state.isFinished != false else {
            return
        }
        
        // If there's a finished operation, remove it first
        if let existingOperation = operations[chapter.queueOperationId],
           existingOperation.state.isFinished {
            operations.removeValue(forKey: chapter.queueOperationId)
        }
        
        // create new operation and add it
        let operation = QueueOperation(item: chapter, type: .chapterDownload(chapter), mangaId: mangaId)
        operations[chapter.queueOperationId] = operation
        
        // when value changes, notify main provider so that views can listen
        operation.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // start subscription to handle queue
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
        
        // once subscription started, try updating queue
        updateQueue()
    }
    
    func refreshMetadata(_ entry: Entry) {
        // Check if operation doesn't exist OR if it exists but is finished
        guard operations[entry.queueOperationId]?.state.isFinished != false else {
            return
        }
        
        // If there's a finished operation, remove it first
        if let existingOperation = operations[entry.queueOperationId],
           existingOperation.state.isFinished {
            operations.removeValue(forKey: entry.queueOperationId)
        }
        
        // create new operation and add it
        let operation = QueueOperation(item: entry, type: .metadataRefresh(entry), mangaId: entry.mangaId)
        operations[entry.queueOperationId] = operation
        
        // when value changes, notify main provider so that views can listen
        operation.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // start subscription to handle queue
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
        
        // once subscription started, try updating queue
        updateQueue()
    }
}

// MARK: - Internal
private extension QueueProvider {
    private func updateQueue() {
        /// Check if there is > 5 queue operations currently ongoing
        
        let ongoingCount = operations.values.filter {
            if case .ongoing = $0.state { return true }
            return false
        }.count
        
        guard ongoingCount < Constants.Queue.ConcurrentOperationsCount else { return }
        
        /// get available pending operations
        
        let pendingOperations = operations.values.filter { $0.state == .pending }
        let slotsAvailable = Constants.Queue.ConcurrentOperationsCount - ongoingCount
        
        /// for available pending operations start their action
        
        // ordered dictionary so using .prefix should retrieve in FIFO order
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

//
//  QueueProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/5/2025.
//

import Foundation
import Combine
import Collections

typealias QueueOperationId = String

protocol QueueOperationIdentifiable {
    var queueOperationId: QueueOperationId { get }
}

enum QueueOperationType {
    case chapterDownload(Chapter)
    case metadataRefresh
}

enum QueueOperationState: Equatable {
    case pending
    case ongoing(Double) // where double is progress -> 0.0 to 1.0
    case completed
    case cancelled
    case failed(Error)
    
    // Equatable conformance for Error case
    static func == (lhs: QueueOperationState, rhs: QueueOperationState) -> Bool {
        switch (lhs, rhs) {
        case (.pending, .pending),
            (.completed, .completed),
            (.cancelled, .cancelled):
            return true
        case let (.ongoing(p1), .ongoing(p2)):
            return p1 == p2
        case let (.failed(e1), .failed(e2)):
            return (e1 as NSError) == (e2 as NSError)
        default:
            return false
        }
    }
}

final class QueueOperation: ObservableObject, Identifiable {
    let id: String
    let type: QueueOperationType
    
    @Published private(set) var state: QueueOperationState
    @Published private(set) var progress: Double
    private var task: Task<Void, Never>?
    
    // expose state publisher
    var publisher: AnyPublisher<QueueOperationState, Never> {
        $state.eraseToAnyPublisher()
    }
    
    init(item: any QueueOperationIdentifiable, type: QueueOperationType) {
        self.id = item.queueOperationId
        self.type = type
        self.state = .pending
        self.progress = 0.0
    }
    
    @MainActor
    func updateState(_ newState: QueueOperationState) {
        self.state = newState

        switch newState {
        case .pending, .failed, .cancelled:
            self.progress = 0.0
        case .ongoing(let progressValue):
            self.progress = progressValue
        case .completed:
            self.progress = 1.0
        }
    }
    
    func start(with stream: AsyncStream<QueueOperationState>) {
        task = Task {
            for await newState in stream {
                await updateState(newState)
            }
        }
    }
    
    @MainActor
    func cancel() {
        task?.cancel()
        updateState(.cancelled)
    }
}

final class QueueProvider: ObservableObject {
    static var shared = QueueProvider()
    
    @Published private(set) var operations: OrderedDictionary<QueueOperationId, QueueOperation> = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private let downloadChapterUseCase: DownloadChapterUseCase
    
    private init() {
        let injector = DependencyInjector.shared
        self.downloadChapterUseCase = injector.makeDownloadChapterUseCase()
    }
}

// MARK: - Getters
extension QueueProvider {
    func getOperation(for id: QueueOperationId) -> QueueOperation? {
        return self.operations[id]
    }
}

// MARK: - Use-cases
extension QueueProvider {
    func downloadChapter(_ chapter: Chapter) {
        guard operations[chapter.queueOperationId] == nil else {
            return
        }
        
        // create new operation and add it
        let operation = QueueOperation(item: chapter, type: .chapterDownload(chapter))
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
}


// MARK: - Internal
extension QueueProvider {
    private func updateQueue() {
        /// Check if there is > 5 queue operations currently ongoing
        
        let ongoingCount = operations.values.filter {
            if case .ongoing = $0.state { return true }
            return false
        }.count
        
        guard ongoingCount < 5 else { return }
        
        /// get available pending operations
        
        let pendingOperations = operations.values.filter { $0.state == .pending }
        let slotsAvailable = 5 - ongoingCount
        
        /// for available pending operations start their action
        
        // ordered dictionary so using .prefix should retrieve in FIFO order
        for operation in pendingOperations.prefix(slotsAvailable) {
            switch operation.type {
            case .chapterDownload(let chapter):
                let stream = downloadChapterUseCase.execute(chapter: chapter)
                operation.start(with: stream)
                
            case .metadataRefresh:
                break
            }
        }
    }
}

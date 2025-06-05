//
//  QueueOperation.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation
import Combine

final class QueueOperation: ObservableObject, Identifiable {
    let id: String
    let mangaId: Int64?
    let type: QueueOperationType
    
    @Published private(set) var state: QueueOperationState
    @Published private(set) var progress: Double
    private var task: Task<Void, Never>?
    
    // expose state publisher
    var publisher: AnyPublisher<QueueOperationState, Never> {
        $state.eraseToAnyPublisher()
    }
    
    init(item: any QueueOperationIdentifiable, type: QueueOperationType, mangaId: Int64?) {
        self.id = item.queueOperationId
        self.type = type
        self.mangaId = mangaId
        
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

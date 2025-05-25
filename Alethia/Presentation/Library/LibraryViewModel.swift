//
//  LibraryViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import SwiftUI
import Combine
import GRDB

final class LibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showFilters: Bool = false
    @Published var filters: LibraryFilters = .init()
    @Published private(set) var state: ViewState = .loading
    
    @Published private(set) var collections: [Collection] = []
    @Published private(set) var activeCollection: Collection? = nil
    
    // MARK: - Properties
    private var cancellables: Set<AnyCancellable> = []
    private let getLibraryUseCase: GetLibraryUseCase
    
    // MARK: - View State
    enum ViewState {
        case loading
        case success
        case error(Error)
        case empty
    }
    
    // MARK: - Computed Properties
    var items: [Entry] {
        switch state {
        case .loading, .empty, .error:
            return []
        case .success:
            return _items
        }
    }
    
    private var _items: [Entry] = []
    
    // MARK: - Initialization
    init() {
        self.getLibraryUseCase = DependencyInjector.shared.makeGetLibraryUseCase()
    }
    
    // MARK: - Lifecycle
    func onAppear() {
        guard cancellables.isEmpty else { return }
        bind()
    }
    
    func setActiveCollection(_ collection: Collection?) -> Void {
        activeCollection = collection
    }
    
    func refreshCollection() -> Void {
        state = .loading
        // Trigger refresh by updating filters
        filters = filters
    }
    
    // MARK: - Private Methods
    private func bind() -> Void {
        state = .loading
        
        // switchToLatest ensure we're always using the latest filter
        $filters
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.state = .loading
            })
            .map { [unowned self] filters in
                self.getLibraryUseCase
                    .execute(filters: filters)
                    .catch { error -> AnyPublisher<[Entry], Never> in
                        // Handle error and return empty publisher
                        DispatchQueue.main.async { [weak self] in
                            self?.state = .error(error)
                        }
                        return Just([]).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                guard let self = self else { return }
                
                // Check if we're not in an error state before setting empty
                let isInErrorState: Bool
                if case .error = self.state {
                    isInErrorState = true
                } else {
                    isInErrorState = false
                }
                
                if updated.isEmpty && !isInErrorState {
                    self.state = .empty
                    self._items = []
                } else if !updated.isEmpty {
                    self._items = updated
                    self.state = .success
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: Filter Controls
extension LibraryViewModel {
    func togglePublishStatus(status: PublishStatus) -> Void {
        if let index = filters.publishStatus.firstIndex(of: status) {
            _ = withAnimation {
                filters.publishStatus.remove(at: index)
            }
        }
        else {
            withAnimation {
                filters.publishStatus.append(status)
            }
        }
    }
    
    func toggleClassification(classification: Classification) -> Void {
        if let index = filters.classification.firstIndex(of: classification) {
            _ = withAnimation {
                filters.classification.remove(at: index)
            }
        }
        else {
            withAnimation {
                filters.classification.append(classification)
            }
        }
    }
    
    func clearFilter(for target: LibraryFilterTarget) -> Void {
        withAnimation {
            switch target {
            case .addedAt:
                filters.addedAt = .none
            case .updatedAt:
                filters.updatedAt = .none
            case .metadata:
                filters.publishStatus.removeAll()
                filters.classification.removeAll()
            case .tags:
                filters.tags.removeAll()
            }
        }
    }
}

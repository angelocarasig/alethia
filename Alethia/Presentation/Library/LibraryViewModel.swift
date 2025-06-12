//
//  LibraryViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import SwiftUI
import Combine
import GRDB

final class LibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: ViewState = .loading
    @Published var filters: LibraryFilters = .init()
    @Published private(set) var collections: [CollectionExtended] = []
    @Published private(set) var activeCollection: Collection? = nil
    
    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    private var _items: [Entry] = []
    
    // MARK: - Dependencies
    private let defaultsProvider = DefaultsProvider.shared
    private let getLibraryUseCase: GetLibraryUseCase
    private let getAllCollectionsUseCase: GetAllCollectionsUseCase
    private let addCollectionUseCase: AddCollectionUseCase
    
    // MARK: - Types
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
    
    var hasActiveFilters: Bool {
        !filters.publishStatus.isEmpty ||
        !filters.classification.isEmpty ||
        !filters.tags.isEmpty ||
        filters.addedAt != .none ||
        filters.updatedAt != .none
    }
    
    var stateIdentifier: String {
        switch state {
        case .loading: return "loading"
        case .success: return "success"
        case .error: return "error"
        case .empty: return "empty"
        }
    }
    
    // MARK: - Initialization
    init() {
        let injector = DependencyInjector.shared
        self.getLibraryUseCase = injector.makeGetLibraryUseCase()
        self.getAllCollectionsUseCase = injector.makeGetAllCollectionsUseCase()
        self.addCollectionUseCase = injector.makeAddCollectionUseCase()
        
        // Initialize filters with saved defaults
        self.filters.sortType = defaultsProvider.librarySortType
        self.filters.sortDirection = defaultsProvider.librarySortDirection
    }
}

// MARK: - Lifecycle Methods
extension LibraryViewModel {
    func onAppear() {
        guard cancellables.isEmpty else { return }
        bind()
    }
    
    func onRefresh() {
        for item in self.items {
            QueueProvider.shared.refreshMetadata(item)
        }
    }
    
    func refreshCollection() {
        withAnimation(.easeInOut(duration: 0.2)) {
            state = .loading
        }
        filters = filters
    }
}

// MARK: - Collection Management
extension LibraryViewModel {
    func setActiveCollection(_ collection: Collection?) {
        withAnimation(.smooth) {
            activeCollection = collection
        }
    }
    
    func createCollection(name: String, color: String, icon: String) throws {
        try addCollectionUseCase.execute(name: name, color: color, icon: icon)
    }
}

// MARK: - Filter Management
extension LibraryViewModel {
    func togglePublishStatus(status: PublishStatus) {
        if let index = filters.publishStatus.firstIndex(of: status) {
            filters.publishStatus.remove(at: index)
        } else {
            withAnimation {
                filters.publishStatus.append(status)
            }
        }
    }
    
    func toggleClassification(classification: Classification) {
        if let index = filters.classification.firstIndex(of: classification) {
            filters.classification.remove(at: index)
        } else {
            withAnimation {
                filters.classification.append(classification)
            }
        }
    }
    
    func clearFilter(for target: LibraryFilterTarget) {
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
    
    func clearAllFilters() {
        withAnimation {
            filters.reset()
        }
    }
}

// MARK: - Private Methods - Binding
private extension LibraryViewModel {
    func bind() {
        withAnimation(.easeInOut(duration: 0.2)) {
            state = .loading
        }
        
        setupDefaultsPublisher()
        setupCollectionsPublisher()
        setupLibraryPublisher()
    }
}

// MARK: - Private Methods - Publishers
private extension LibraryViewModel {
    func setupDefaultsPublisher() {
        // Sync DefaultsProvider changes to filters
        defaultsProvider.libraryPublisher
            .sink { [weak self] sorting in
                guard let self = self else { return }
                // Only update if different to avoid infinite loop
                if self.filters.sortType != sorting.type {
                    self.filters.sortType = sorting.type
                }
                if self.filters.sortDirection != sorting.direction {
                    self.filters.sortDirection = sorting.direction
                }
            }
            .store(in: &cancellables)
        
        // Sync filter changes to DefaultsProvider
        $filters
            .sink { [weak self] filters in
                guard let self = self else { return }
                // Only update if different to avoid infinite loop
                if self.defaultsProvider.librarySortType != filters.sortType {
                    self.defaultsProvider.librarySortType = filters.sortType
                }
                if self.defaultsProvider.librarySortDirection != filters.sortDirection {
                    self.defaultsProvider.librarySortDirection = filters.sortDirection
                }
            }
            .store(in: &cancellables)
    }
    
    func setupCollectionsPublisher() {
        getAllCollectionsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] collections in
                withAnimation(.smooth(duration: 0.3)) {
                    self?.collections = collections
                }
            }
            .store(in: &cancellables)
    }
    
    func setupLibraryPublisher() {
        /// Getting collection -> whenever filters or active collection changes we execute
        /// the use-case with the updated filters/current collection
        Publishers.CombineLatest($filters, $activeCollection)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self?.state = .loading
                }
            })
            .map { [unowned self] filters, activeCollection in
                self.getLibraryUseCase
                    .execute(filters: filters, collection: activeCollection?.id)
                    .subscribe(on: DispatchQueue.global(qos: .userInitiated)) // chuck in background but receive on main
                    .receive(on: DispatchQueue.main)
                    .catch { error -> AnyPublisher<[Entry], Never> in
                        DispatchQueue.main.async { [weak self] in
                            print("Something Went Wrong: \(error)")
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self?.state = .error(error)
                            }
                        }
                        return Just([]).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                guard let self = self else { return }
                
                let isInErrorState: Bool
                if case .error = self.state {
                    isInErrorState = true
                } else {
                    isInErrorState = false
                }
                
                withAnimation(.smooth(duration: 0.3, extraBounce: 0.1)) {
                    if updated.isEmpty && !isInErrorState {
                        self.state = .empty
                        self._items = []
                    } else if !updated.isEmpty {
                        self._items = updated
                        self.state = .success
                    }
                }
            }
            .store(in: &cancellables)
    }
}

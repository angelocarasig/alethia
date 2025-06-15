//
//  LibraryViewModel.swift
//  Composition
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import Combine
import SwiftUI

public protocol LibraryViewModel: ObservableObject {
    var state: LibraryViewState { get }
    var filters: Domain.Models.Presentation.LibraryFilters { get set }
    var collectionId: Int64? { get set }
}

public enum LibraryViewState: Equatable {
    case idle
    case loading
    case loaded([Domain.Models.Virtual.Entry])
    case error(Error)
    case empty
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.loading, .loading),
            (.empty, .empty):
            return true
        case let (.loaded(lhsEntries), .loaded(rhsEntries)):
            return lhsEntries.count == rhsEntries.count
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

internal final class LibraryViewModelImpl: LibraryViewModel {
    @Published private(set) var state: LibraryViewState = .idle
    
    @Published var collectionId: Int64? = nil
    @Published var filters = Domain.Models.Presentation.LibraryFilters()
    
    private var cancellables = Set<AnyCancellable>()
    private let getLibraryUseCase: GetLibraryUseCase
    
    init(getLibraryUseCase: GetLibraryUseCase) {
        // use-cases
        self.getLibraryUseCase = getLibraryUseCase
        
        // internal
        setupBindings()
    }
    
    private func setupBindings() {
        Publishers.CombineLatest($filters, $collectionId)
            .sink { [weak self] filters, collectionId in
                self?.loadLibrary(filters: filters, collectionId: collectionId)
            }
            .store(in: &cancellables)
    }
    
    private func loadLibrary(filters: Domain.Models.Presentation.LibraryFilters, collectionId: Int64?) {
        state = .loading
        
        getLibraryUseCase
            .execute(filters: filters, collectionId: collectionId)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state = .error(error)
                    }
                },
                receiveValue: { [weak self] entries in
                    guard let self = self else { return }
                    
                    if entries.isEmpty {
                        self.state = .empty
                    } else {
                        self.state = .loaded(entries)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

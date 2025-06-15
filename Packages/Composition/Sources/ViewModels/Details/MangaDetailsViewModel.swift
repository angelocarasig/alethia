//
//  MangaDetailsViewModel.swift
//  Composition
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Domain
import Combine
import SwiftUI

public protocol MangaDetailsViewModel: ObservableObject {
    var state: MangaDetailsViewState { get }
    var entry: Domain.Models.Virtual.Entry { get }
    
    func resolveConflict(_ details: Domain.Models.Virtual.Details, sourceId: Int64)
}

public enum MangaDetailsViewState: Equatable {
    case loading
    case conflict([Domain.Models.Virtual.Details])
    case loaded(Domain.Models.Virtual.Details)
    case error(Error)
    case empty
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
            (.empty, .empty):
            return true
        case let (.conflict(lhsDetails), .conflict(rhsDetails)):
            return lhsDetails.count == rhsDetails.count
        case let (.loaded(lhsDetail), .loaded(rhsDetail)):
            return lhsDetail.manga.id == rhsDetail.manga.id
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

internal final class MangaDetailsViewModelImpl: MangaDetailsViewModel {
    @Published private(set) var state: MangaDetailsViewState = .loading
    @Published private(set) var entry: Domain.Models.Virtual.Entry
    
    private var cancellables = Set<AnyCancellable>()
    private let getMangaDetailsUseCase: GetMangaDetailsUseCase
    
    init(
        entry: Domain.Models.Virtual.Entry,
        getMangaDetailsUseCase: GetMangaDetailsUseCase
    ) {
        // base
        self.entry = entry
        
        // use-cases
        self.getMangaDetailsUseCase = getMangaDetailsUseCase
        
        // internal
        setupBindings()
    }
    
    /// when multiple details are found, this function is called on the selected detail to be resolving
    func resolveConflict(_ details: Domain.Models.Virtual.Details, sourceId: Int64) {
        // Update entry with resolved information
        self.entry = details.toEntry(sourceId: sourceId, from: entry)
        
        // trigger reload which will now resolve to single match
        setupBindings()
    }
    
    private func setupBindings() {
        // cancel existing subscriptions
        cancellables.removeAll()
        
        state = .loading
        
        getMangaDetailsUseCase
            .execute(entry: entry)
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.state = .error(error)
                    }
                },
                receiveValue: { [weak self] details in
                    guard let self = self else { return }
                    
                    switch details.count {
                    case 0:
                        self.state = .empty
                    case 1:
                        self.state = .loaded(details[0])
                        // Update entry's mangaId for future operations
                        self.entry.mangaId = details[0].manga.id
                    default:
                        self.state = .conflict(details)
                    }
                }
            )
            .store(in: &cancellables)
    }
}

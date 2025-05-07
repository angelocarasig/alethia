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
    @Published var showFilters: Bool = false
    @Published var filters: LibraryFilters = .init()
    
    @Published var items: [Entry] = []
    
    @Published private(set) var collections: [Collection] = []
    @Published private(set) var activeCollection: Collection? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    private let getLibraryUseCase: GetLibraryUseCase
    
    init() {
        self.getLibraryUseCase = DependencyInjector.shared.makeGetLibraryUseCase()
        
        $filters
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .flatMap { [unowned self] filters in
                self.getLibraryUseCase
                    .execute(filters: filters)
                    .catch { _ in Just([]) } // just catch errors for now
            }
            .receive(on: RunLoop.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Library fetch failed:", error)
                }
            } receiveValue: { [weak self] updated in
                self?.items = updated
            }
            .store(in: &cancellables)
    }
    
    func setActiveCollection(_ collection: Collection?) -> Void {
        activeCollection = collection
    }
    
    func refreshCollection() -> Void {
        
    }
}

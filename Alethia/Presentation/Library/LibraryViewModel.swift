//
//  LibraryViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/4/2025.
//

import Foundation
import Combine
import GRDB

final class LibraryViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var showFilters: Bool = false
    
    @Published var items: [Entry] = []
    
    @Published private(set) var collections: [Collection] = []
    @Published private(set) var activeCollection: Collection? = nil
    
    private var cancellables: Set<AnyCancellable> = []
    private let getLibraryUseCase: GetLibraryUseCase
    
    init() {
        self.getLibraryUseCase = DependencyInjector.shared.makeGetLibraryUseCase()
    }
    
    func bind() -> Void {
        cancellables.removeAll()
        
        getLibraryUseCase
            .execute()
            .receive(on: RunLoop.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Error: \(error)")
                }
            } receiveValue: { [weak self] items in
                print("Item 1: \(items[0])")
                self?.items = items
            }
            .store(in: &cancellables)
    }
    
    func setActiveCollection(_ collection: Collection?) -> Void {
        activeCollection = collection
    }
    
    func refreshCollection() -> Void {
        
    }
}

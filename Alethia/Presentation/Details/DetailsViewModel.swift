//
//  DetailsViewModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Foundation
import Combine

final class DetailsViewModel: ObservableObject {
    @Published var details: Detail? = nil
    @Published var error: Error? = nil
    @Published var loading: Bool = false
    
    enum Tabs: String, CaseIterable {
        case details = "Details"
        case manage = "Manage"
        case chapters = "Chapters"
        case artwork = "Artwork"
    }
    @Published var activeTab: Tabs = .details
    
    private var cancellables = Set<AnyCancellable>()
    private let getMangaDetailUseCase: GetMangaDetailUseCase
    
    var entry: Entry
    
    init(entry: Entry? = nil) {
        self.entry = Entry(
            mangaId: nil,
            sourceId: 1,
            title: "Guild no Uketsukejou Desu ga, Zangyou wa Iya Nanode Boss wo Solo Toubatsu Shiyou to Omoimasu",
            cover: nil,
            fetchUrl: "https://fortune.alethia.workers.dev/mangadex/manga/3b9bade6-28a0-4f2f-8211-4b5106a2cbbd"
        )
        
        self.getMangaDetailUseCase = DependencyInjector.shared.makeGetMangaDetailUseCase()
    }
    
    func bind() {
        loading = true
        error = nil
        
        getMangaDetailUseCase.execute(entry: self.entry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.loading = false
                
                if case .failure(let error) = completion {
                    self.error = error
                }
            } receiveValue: { [weak self] detail in
                self?.details = detail
                print("Received detail: \(self?.details?.manga.title)")
            }
            .store(in: &cancellables)
    }
    
    func setActiveTab(_ tab: Tabs) -> Void {
        self.activeTab = tab
    }
}

// MARK: State

extension DetailsViewModel {
    enum State {
        case loading
        case success(Detail)
        case error(Error)
        case empty
    }
    
    var state: State {
        if loading {
            return .loading
        } else if let details {
            return .success(details)
        } else if let error {
            return .error(error)
        } else {
            return .empty
        }
    }
}

//
//  SourcesViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 5/10/2025.
//

import SwiftUI
import Composition
import Domain

@MainActor
@Observable
final class SourcesViewModel {
    private(set) var hosts: [Host] = []
    private(set) var isLoading = true
    private var observationTask: Task<Void, Never>?
    
    @ObservationIgnored
    private let getAllHostsUseCase: GetAllHostsUseCase
    
    init() {
        self.getAllHostsUseCase = Injector.makeGetAllHostsUseCase()
    }
    
    func startObserving() {
        // cancel any existing observation
        observationTask?.cancel()
        
        // start new observation
        observationTask = Task { @MainActor in
            isLoading = true
            
            for await hosts in getAllHostsUseCase.execute() {
                if Task.isCancelled { break }
                
                self.hosts = hosts
                self.isLoading = false
            }
        }
    }
    
    func stopObserving() {
        observationTask?.cancel()
        observationTask = nil
    }
    
    var isEmpty: Bool {
        hosts.isEmpty && !isLoading
    }
    
    func sources(for hostId: Int64? = nil, matching searchText: String = "") -> [Source] {
        let allSources = hosts.flatMap(\.sources)
        
        var filtered = allSources
        
        // filter by host if specified
        if let hostId = hostId {
            let host = hosts.first { $0.id == hostId }
            if let host = host {
                filtered = host.sources
            }
        }
        
        // filter by search text if not empty
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            filtered = filtered.filter {
                $0.name.lowercased().contains(lowercased) ||
                $0.host.lowercased().contains(lowercased)
            }
        }
        
        return filtered
    }
    
    var totalEnabledCount: Int {
        hosts.flatMap(\.sources).filter { !$0.disabled }.count
    }
}

//
//  SettingsSourcesView.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Core
import SwiftUI
import Combine

struct SettingsSourcesView: View {
    @StateObject private var vm = ViewModel()
    
    var body: some View {
        Group {
            if vm.hosts.isEmpty {
                Text("No hosts found.")
            } else {
                List {
                    HostListView()
                }
            }
        }
        .onAppear {
            vm.bind()
        }
    }
    
    @ViewBuilder
    private func HostListView() -> some View {
        ForEach(vm.hosts) { host in
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.accentColor)
                Text(host.name)
                Spacer()
            }
            .padding(.vertical, .Padding.minimal)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    vm.delete(host)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    @ViewBuilder
    private func SourcesListView() -> some View {
        ForEach(vm.hosts) { host in
            HStack {
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.accentColor)
                Text(host.name)
                Spacer()
            }
            .padding(.vertical, .Padding.minimal)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    vm.delete(host)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private final class ViewModel: ObservableObject {
    @Published private(set) var hosts: [Host] = []
    
    private var cancellables: Set<AnyCancellable> = []
    private let getHostsUseCase: GetHostsUseCase
    private let deleteHostUseCase: DeleteHostUseCase
    
    init() {
        self.getHostsUseCase = DependencyInjector.shared.makeGetHostsUseCase()
        self.deleteHostUseCase = DependencyInjector.shared.makeDeleteHostUseCase()
    }
    
    func bind() {
        getHostsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hosts in
                withAnimation {
                    self?.hosts = hosts
                }
            }
            .store(in: &cancellables)
    }
    
    func delete(_ host: Host) -> Void {
        do {
            // 🫡
            try deleteHostUseCase.execute(host)
        } catch {
            print("Error deleting host: \(error)")
        }
    }
}

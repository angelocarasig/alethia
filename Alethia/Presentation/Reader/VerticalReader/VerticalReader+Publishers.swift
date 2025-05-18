//
//  VerticalReader+Publishers.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import Foundation

extension VerticalReaderController {
    func setupBindings() {
        listenToReaderState()
    }
    
    private func listenToReaderState() {
        vm.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &vm.cancellables)
    }
}

// MARK: Handlers
private extension VerticalReaderController {
    func handleStateChange(_ state: ReaderState) {
        switch state {
        case .idle:
            node.reloadData() // Data has been loaded, reload collection view
        case .error(let error):
            print("Error: \(error.localizedDescription)")
            
        default:
            break
        }
    }
}

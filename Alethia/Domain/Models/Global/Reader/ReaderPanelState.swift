//
//  ReaderPanelState.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import Foundation

enum PanelLoadedState: Equatable {
    case loaded
    case loading
    case error(Error)
    
    static func == (lhs: PanelLoadedState, rhs: PanelLoadedState) -> Bool {
        switch (lhs, rhs) {
        case (.loaded, .loaded), (.loading, .loading):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

struct ReaderPanelState {
    var panels: [ReaderPanel]? // would be nil if loading/error
    var state: PanelLoadedState
}

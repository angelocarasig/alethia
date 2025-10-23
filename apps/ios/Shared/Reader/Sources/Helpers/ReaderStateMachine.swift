//
//  ReaderStateMachine.swift
//  Reader
//
//  Created by Angelo Carasig on 24/10/2025.
//

import Foundation

/// reason for page/chapter changes
public enum ChangeReason: Sendable {
    case userScroll
    case programmaticJump
    case preloadInsert
    case initialLoad
}

/// reader state for coordinated transitions
enum ReaderState: Sendable, Equatable {
    static func == (lhs: ReaderState, rhs: ReaderState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loadingInitial, .loadingInitial),
             (.loadingPrevious, .loadingPrevious),
             (.loadingNext, .loadingNext),
             (.inserting, .inserting),
             (.settling, .settling),
             (.ready, .ready):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            // compare error descriptions since Error isn't Equatable
            return (lhsError as NSError) == (rhsError as NSError)
        default:
            return false
        }
    }
    
    case idle
    case loadingInitial
    case loadingPrevious
    case loadingNext
    case inserting
    case settling
    case ready
    case error(Error)
}

/// manages reader state transitions to prevent races
@MainActor
final class ReaderStateMachine {
    private(set) var state: ReaderState = .idle
    private var stateChangeCallbacks: [(ReaderState) -> Void] = []
    
    /// attempt state transition - returns true if allowed
    func transition(to newState: ReaderState) -> Bool {
        let allowed = isTransitionAllowed(from: state, to: newState)
        
        if allowed {
            print("[StateMachine] Transitioning from \(state) to \(newState)")
            state = newState
            notifyStateChange()
        } else {
            print("[StateMachine] Transition from \(state) to \(newState) not allowed")
        }
        
        return allowed
    }
    
    /// register callback for state changes
    func onStateChange(_ callback: @escaping (ReaderState) -> Void) {
        stateChangeCallbacks.append(callback)
    }
    
    private func isTransitionAllowed(from: ReaderState, to: ReaderState) -> Bool {
        switch (from, to) {
        // initial load path
        case (.idle, .loadingInitial),
             (.loadingInitial, .inserting),
             (.loadingInitial, .error):
            return true
            
        // chapter navigation paths
        case (.ready, .loadingPrevious),
             (.ready, .loadingNext),
             (.loadingPrevious, .inserting),
             (.loadingNext, .inserting),
             (.loadingPrevious, .ready), // cancelled/already loaded
             (.loadingNext, .ready):     // cancelled/already loaded
            return true
            
        // insertion to settling
        case (.inserting, .settling):
            return true
            
        // settling to ready
        case (.settling, .ready):
            return true
            
        // error recovery
        case (.error, .loadingInitial),
             (.error, .idle):
            return true
            
        // allow transitioning to error from most states
        case (_, .error):
            return true
            
        default:
            return false
        }
    }
    
    private func notifyStateChange() {
        for callback in stateChangeCallbacks {
            callback(state)
        }
    }
    
    /// check if we can start loading
    var canStartLoading: Bool {
        switch state {
        case .ready, .idle:
            return true
        default:
            return false
        }
    }
    
    /// check if we're in a loading state
    var isLoading: Bool {
        switch state {
        case .loadingInitial, .loadingPrevious, .loadingNext, .inserting, .settling:
            return true
        default:
            return false
        }
    }
}

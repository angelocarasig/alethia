//
//  Loadable.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

enum Loadable<T> {
    case idle
    case loading
    case loaded(T)
    case failed(Error)
    
    var value: T? {
        switch self {
        case let .loaded(value): return value
        default: return nil
        }
    }
    
    var error: Error? {
        switch self {
        case let .failed(error): return error
        default: return nil
        }
    }
}

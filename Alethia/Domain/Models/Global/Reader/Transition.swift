//
//  Transition.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

struct Transition: Hashable, Sendable {
    let from: Chapter
    let to: Chapter?
    let type: TransitionType
    let pageCount: Int?
    
    enum TransitionType: Hashable {
        case next, previous
    }
    
    init(from: Chapter, to: Chapter?, type: TransitionType, pageCount: Int? = nil) {
        self.from = from
        self.to = to
        self.type = type
        self.pageCount = pageCount
    }
}

//
//  ReaderPanel.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

enum ReaderPanel {
    case transition(Transition)
    case page(Page)
    
    var chapter: Chapter {
        switch self {
        case let .transition(transition):
            return transition.from
        case let .page(page):
            return page.chapter
        }
    }
    
    var isPage: Bool {
        switch self {
        case .page:
            return true
        case .transition:
            return false
        }
    }
}

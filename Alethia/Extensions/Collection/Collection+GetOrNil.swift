//
//  Collection+GetOrNil.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import Foundation

extension Swift.Collection {
    func getOrNil(_ index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

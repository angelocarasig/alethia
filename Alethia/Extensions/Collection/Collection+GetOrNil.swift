//
//  Collection+GetOrNil.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation

extension Swift.Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    func getOrNil(_ index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

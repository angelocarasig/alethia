//
//  String+DecodeUri.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/2/2025.
//

import Foundation

extension String {
    var decodeUri: String {
        var current = self
        while true {
            // Attempt to decode the current string
            let decoded = current.removingPercentEncoding ?? current
            
            // If decoding did not change the string, we're done
            if decoded == current {
                return current
            }
            
            // Otherwise, keep decoding
            current = decoded
        }
    }
}

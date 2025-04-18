//
//  Utilities.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

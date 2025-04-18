//
//  ContentView.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import SwiftUI


struct ContentView: View {
    
    var body: some View {
        NavigationStack {
            
            NavigationLink(destination: DetailsScreen()) {
                Text("View Default...")
            }
        }
    }
}

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

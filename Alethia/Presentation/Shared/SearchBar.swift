//
//  SearchBar.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    var placeholder: String = "Search";
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            TextField(placeholder, text: $searchText)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .accessibilityLabel("Search collections")
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 17))
                }
                .accessibilityLabel("Clear search")
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding()
        .frame(height: 44)
        .background(Color.tint)
        .cornerRadius(10)
    }
}


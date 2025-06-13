//
//  SearchBar.swift
//  Alethia
//
//  Created by Angelo Carasig on 26/11/2024.
//

import Core
import SwiftUI

struct SearchBar: View {
    @Binding var searchText: String
    var placeholder: String
    var onXTapped: (() -> Void)?
    
    init(
        searchText: Binding<String>,
        placeholder: String = "Search",
        onXTapped: (() -> Void)? = nil
    ) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onXTapped = onXTapped
    }
    
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
                Button {
                    if let onXTapped = onXTapped {
                        onXTapped()
                    } else {
                        searchText = ""
                    }
                } label: {
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
        .cornerRadius(.Corner.regular)
    }
}


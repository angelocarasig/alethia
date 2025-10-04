//
//  Searchbar.swift
//  Presentation
//
//  Created by Angelo Carasig on 17/6/2025.
//

import Core
import SwiftUI

internal struct Searchbar: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
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
            
            TextField(placeholder, text: $searchText)
                .autocorrectionDisabled()
                .autocapitalization(.none)
            
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
                        .font(.headline)
                }
                .animation(.easeInOut, value: searchText)
            }
        }
        .padding()
        .frame(height: 45)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.regular)
        .scrollDismissesKeyboard(.immediately)
    }
}


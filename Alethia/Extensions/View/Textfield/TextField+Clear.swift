//
//  TextField+Clear.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI

extension View {
    func clearButton(text: Binding<String>) -> some View {
        self.modifier(TextFieldClearButton(text: text))
    }
}

struct TextFieldClearButton: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        HStack {
            content
            if !text.isEmpty && text != "..." {
                Button {
                    text = ""
                } label: {
                    Text("Clear")
                }
            }
        }
    }
}

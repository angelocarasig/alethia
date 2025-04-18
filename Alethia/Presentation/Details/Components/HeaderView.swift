//
//  HeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let authors: [Author]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(authors.map { $0.name }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc.fill")
            }
        }
    }
}

//
//  TagsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct TagsView: View {
    let tags: [Tag]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags.map { $0.name }.sorted(), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.tint)
                        .foregroundColor(.text.opacity(0.75))
                        .cornerRadius(15)
                }
            }
        }
        .listRowInsets(EdgeInsets())
    }
}

//
//  TagsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct TagsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var tags: [Tag] {
        vm.details?.tags ?? []
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags.map { $0.name }.sorted(), id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(.text.opacity(0.75))
                        .padding(.horizontal, Constants.Padding.regular)
                        .padding(.vertical, Constants.Padding.minimal)
                        .background(Color.tint)
                        .cornerRadius(Constants.Corner.Radius.button)
                }
            }
        }
        .listRowInsets(EdgeInsets())
    }
}

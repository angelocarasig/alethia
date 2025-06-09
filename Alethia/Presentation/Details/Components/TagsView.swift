//
//  TagsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI
import Flow

struct TagsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    @State private var showAll = false
    
    var tags: [Tag] {
        vm.details?.tags ?? []
    }
    
    private var visibleTags: [String] {
        let sortedTags = tags.map { $0.name }.sorted()
        return showAll ? sortedTags : Array(sortedTags.prefix(10))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HFlow {
                ForEach(visibleTags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .foregroundStyle(.text.opacity(0.75))
                        .padding(.horizontal, Constants.Padding.regular)
                        .padding(.vertical, Constants.Padding.minimal)
                        .background(Color.tint)
                        .cornerRadius(Constants.Corner.Radius.button)
                }
            }
            
            if tags.count > 10 {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            showAll.toggle()
                        }
                    } label: {
                        Text(Image(systemName: showAll ? "chevron.up" : "chevron.down"))
                        Text(showAll ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .offset(y: 5)
            }
        }
        .onTapGesture { withAnimation { showAll.toggle() } }
    }
}

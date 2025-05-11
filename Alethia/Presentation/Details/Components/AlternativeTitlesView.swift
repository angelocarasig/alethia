//
//  AlternativeTitlesView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI

struct AlternativeTitlesView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var titles: [Title] {
        vm.details?.titles ?? []
    }
    
    @State private var isExpanded: Bool = false
    @State private var truncated: Bool = false
    
    private func determineTruncation(_ geometry: GeometryProxy) {
        let lineHeight = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let maxHeight = lineHeight * 6
        
        let totalHeight = CGFloat(titles.count) * lineHeight
        
        if totalHeight > maxHeight {
            self.truncated = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
            Text("Alternative Titles")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                ForEach(isExpanded ? titles : Array(titles.prefix(5)), id: \.self.id) { title in
                    Text(title.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        self.determineTruncation(geometry)
                    }
                }
            )
            .contentShape(.rect)
            .onTapGesture {
                if truncated {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
            
            if truncated {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

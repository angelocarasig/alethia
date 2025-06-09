//
//  SynopsisView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct SynopsisView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var synopsis: String {
        vm.details?.manga.synopsis ?? "No Description"
    }
    
    @State private var isExpanded: Bool = false
    @State private var truncated: Bool = false
    
    
    private func determineTruncation(_ geometry: GeometryProxy) {
        let total = self.synopsis.boundingRect(
            with: CGSize(width: geometry.size.width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 16)],
            context: nil
        )
        
        let lineHeight = UIFont.systemFont(ofSize: 16).lineHeight
        let maxHeight = lineHeight * 6
        
        if total.size.height > maxHeight {
            self.truncated = true
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(synopsis)
                .lineLimit(isExpanded ? nil : 6)
                .multilineTextAlignment(.leading)
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            self.determineTruncation(geometry)
                        }
                    }
                )
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            
            if truncated {
                HStack {
                    Spacer()
                    Button {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(Image(systemName: isExpanded ? "chevron.up" : "chevron.down"))
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .offset(y: 5)
            }
        }
    }
}

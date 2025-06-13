//
//  TrackingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import Core
import SwiftUI

struct TrackingView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: .Spacing.regular) {
            HStack {
                Text("Tracking")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Image("AniList")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: .Icon.regular.width,
                        height: .Icon.regular.height
                    )
                    .cornerRadius(.Corner.regular)
                
                VStack(alignment: .leading) {
                    Text(vm.details?.manga.title ?? "Unknown Title")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text({
                        let authors = vm.details?.authors ?? []
                        return authors.isEmpty ? "Unknown Author" : authors.map { $0.name }.joined(separator: ", ")
                    }())
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("1/\(999) Chapters")
                        .font(.caption)
                    Text("Reading")
                        .font(.caption)
                        .padding(.horizontal, .Padding.regular)
                        .padding(.vertical, .Padding.minimal)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(.Corner.regular)
                }
            }
        }
        .opacity(vm.inLibrary ? 1 : 0.5)
    }
}

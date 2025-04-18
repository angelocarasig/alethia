//
//  TrackingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/4/2025.
//

import SwiftUI

struct TrackingView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    var details: Detail {
        vm.details!
    }
    
    // TODO: 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                VStack(alignment: .leading) {
                    Text(details.manga.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(details.authors.map { $0.name }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("1/\(999) Chapters")
                        .font(.caption)
                    Text("Reading")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .opacity(details.manga.inLibrary ? 1 : 0.5)
    }
}

//
//  HeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI
import Kingfisher

struct HeaderView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var cover: Cover? {
        vm.details?.covers.first(where: { $0.active })
    }
    
    var title: String {
        vm.details?.manga.title ?? "No Title"
    }
    
    var authors: [Author] {
        vm.details?.authors ?? []
    }
    
    let cellWidth: CGFloat = 125
    var cellHeight: CGFloat {
        cellWidth * 22 / 17
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            KFImage(URL(string: cover?.url ?? ""))
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: cellWidth * 2.5, height: cellHeight * 2.5)))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .fade(duration: 0.25)   
                .scaledToFill()
                .frame(width: cellWidth, height: cellHeight)
                .cornerRadius(8)
                .clipped()
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(authors.map { $0.name }.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}


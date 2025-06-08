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
    @State private var showArtwork: Bool = false
    @State private var imageSize: CGSize = .zero
    
    var title: String {
        vm.details?.manga.title ?? "No Title"
    }
    
    var authors: [Author] {
        vm.details?.authors ?? []
    }
    
    let maxWidth: CGFloat = 200
    let maxHeight: CGFloat = 200
    
    // used for image calculation
    private var displaySize: CGSize {
        guard imageSize.width > 0 else {
            return CGSize(width: maxWidth, height: maxHeight)
        }
        let aspect = imageSize.width / imageSize.height
        
        // start by fitting to maxWidth
        var width = maxWidth
        var height = width / aspect
        
        // if that exceeds maxHeight, fit to maxHeight instead
        if height > maxHeight {
            height = maxHeight
            width = height * aspect
        }
        
        return CGSize(width: width, height: height)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            KFImage(URL(string: vm.activeCover?.url ?? ""))
                .onSuccess { result in
                    imageSize = result.image.size
                }
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .frame(width: displaySize.width, height: displaySize.height)
                .clipShape(.rect(cornerRadius: Constants.Corner.Radius.regular, style: .continuous))
                .onTapGesture { showArtwork = true }
            
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
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                } label: {
                    Label("Copy Title", systemImage: "doc.on.doc")
                }
                
                Button {
                    let authorsText = authors.map { $0.name }.joined(separator: ", ")
                    UIPasteboard.general.string = authorsText
                    
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                } label: {
                    Label("Copy ^[\(authors.count) Author](inflect: true)", systemImage: "doc.on.doc")
                }
            }
        }
        .sheet(isPresented: $showArtwork) {
            ArtworkListView()
        }
    }
}

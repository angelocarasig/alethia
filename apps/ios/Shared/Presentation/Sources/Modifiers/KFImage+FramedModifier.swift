//
//  KFImage+FramedModifier.swift
//  Presentation
//
//  Created by Angelo Carasig on 17/6/2025.
//

import SwiftUI
import Kingfisher

private struct KFImageFramed: View {
    let image: KFImage
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    @State private var imageSize: CGSize = .zero
    
    private var displaySize: CGSize {
        guard imageSize.width > 0 else {
            return CGSize(width: maxWidth, height: maxHeight)
        }
        
        let aspect = imageSize.width / imageSize.height
        
        var width = maxWidth
        var height = width / aspect
        
        if height > maxHeight {
            height = maxHeight
            width = height * aspect
        }
        
        return CGSize(width: width, height: height)
    }
    
    var body: some View {
        image
            .onSuccess { result in
                imageSize = result.image.size
            }
            .resizable()
            .scaledToFit()
            .frame(width: displaySize.width, height: displaySize.height)
    }
}

extension KFImage {
    func framed(maxWidth: CGFloat, maxHeight: CGFloat) -> some View {
        KFImageFramed(image: self, maxWidth: maxWidth, maxHeight: maxHeight)
    }
}

//
//  RetryableImage.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/9/2024.
//

import SwiftUI
import Kingfisher

struct RetryableImage: View {
    let url: String
    let index: String
    let referer: String
    
    @State private var loadingProgress: Double? = nil
    @State private var reloadID = UUID()
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @State private var loadedImage: UIImage? = nil // State to hold the loaded image
    
    var body: some View {
        ZStack {
            KFImage(URL(string: url))
                .requestModifier(RefererModifier(referer: referer))
            
                .onProgress { receivedSize, totalSize in
                    let progress = Double(receivedSize) / Double(totalSize)
                    loadingProgress = progress
                }
                .onSuccess { result in
                    loadingProgress = 1.0
                    loadedImage = result.image // Store the loaded image
                }
                .onFailure { _ in
                    loadingProgress = 0.0
                    loadedImage = nil // Clear the image if failed
                }
                .retry(maxCount: 5, interval: .seconds(0.5))
                .cacheOriginalImage()
                .backgroundDecode()
                .resizable()
                .aspectRatio(contentMode: .fill)
                .id(reloadID)
            
            // NOTE: Can't apply .zoomable to this or else webtoon-view breaks!
            
                .contextMenu {
                    if let _ = loadedImage {
                        Button {
                            copyImageToClipboard()
                        } label: {
                            Label("Copy Image", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            saveImageToPhotos()
                        } label: {
                            Label("Save Image (TODO)", systemImage: "square.and.arrow.down")
                        }
                        .disabled(true)
                    }
                }
            
            ProgressHandler()
        }
        .background(Color.background)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Action Completed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

private extension RetryableImage {
    @ViewBuilder
    func ProgressHandler() -> some View {
        if let progress = loadingProgress {
            if progress == 0 {
                // Image failed to load; show Retry button
                ReaderImageRetry {
                    // Remove the image from cache
                    ImageCache.default.removeImage(forKey: url)
                    // Change reloadID to force KFImage to reload
                    reloadID = UUID()
                    // Reset loading progress
                    loadingProgress = nil
                    loadedImage = nil
                }
                .accessibilityLabel("Retry Button")
                .accessibilityHint("Double-tap to retry loading the image")
            } else if progress > 0 && progress < 1 {
                // Image is loading; show progress indicator
                ReaderImageProgress(progress: progress)
                    .frame(width: 50, height: 50)
                    .accessibilityLabel("Image Loading Progress")
                    .accessibilityHint("Image is loading")
            }
        }
    }
    
    func copyImageToClipboard() {
        guard let image = loadedImage else {
            alertMessage = "Image not available to copy."
            showingAlert = true
            return
        }
        UIPasteboard.general.image = image
        alertMessage = "Image copied to clipboard."
        showingAlert = true
    }
    
    func saveImageToPhotos() {
        guard let image = loadedImage else {
            alertMessage = "Image not available to save."
            showingAlert = true
            return
        }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        alertMessage = "Image saved to Photos."
        showingAlert = true
    }
}

private struct RefererModifier : AsyncImageDownloadRequestModifier {
    let referer: String
    
    func modified(for request: URLRequest) async -> URLRequest? {
        var modifiedRequest = request
        modifiedRequest.setValue(referer, forHTTPHeaderField: "Referer")
        
        return modifiedRequest
    }
    
    var onDownloadTaskStarted: (@Sendable (Kingfisher.DownloadTask?) -> Void)?
}

private struct ReaderImageProgress: View {
    var progress: Double // Between 0.0 and 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.tint.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.text, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Start progress from the top
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .bold()
                .foregroundColor(.text)
        }
        .frame(width: 50, height: 50)
    }
}

private struct ReaderImageRetry: View {
    var callback: () -> Void
    
    var body: some View {
        Button {
            callback()
        } label: {
            Text("Retry")
                .font(.system(size: 16))
                .padding(.horizontal, Constants.Padding.screen)
                .padding(.vertical, Constants.Padding.regular)
                .background(Color.appRed)
                .foregroundColor(.white)
                .cornerRadius(Constants.Corner.Radius.regular)
        }
    }
}

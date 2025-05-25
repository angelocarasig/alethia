//
//  RetryableImage.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/9/2024.
//

import Foundation
import SwiftUI
import Kingfisher
import PhotosUI

struct RetryableImage: View {
    let url: String
    let referer: String
    
    @State private var loadingState: LoadingState = .idle
    @State private var reloadID = UUID()
    @State private var loadedImage: UIImage?
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    private enum LoadingState: Equatable {
        case idle
        case loading(Double)
        case loaded
        case failed
    }
    
    var body: some View {
        KFImage(URL(string: url))
            .requestModifier(RefererModifier(referer: referer))
            .setProcessor(
                DownsamplingImageProcessor(
                    size: CGSize(
                        width: UIScreen.main.bounds.width * UIScreen.main.scale,
                        height: UIScreen.main.bounds.height * UIScreen.main.scale
                    )
                )
            )
            .onProgress { receivedSize, totalSize in
                loadingState = .loading(Double(receivedSize) / Double(totalSize))
            }
            .onSuccess { result in
                loadingState = .loaded
                loadedImage = result.image
            }
            .onFailure { _ in
                loadingState = .failed
            }
            .placeholder { _ in
                Color.background
                    .frame(
                        width: UIScreen.main.bounds.width,
                        height: UIScreen.main.bounds.height
                    )
            }
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .id(reloadID)
            .overlay(alignment: .center) {
                ProgressOverlay(state: loadingState) {
                    retryLoading()
                }
            }
            .background(Color.background)
            .clipped()
            .contextMenu {
                if loadingState == .loaded, loadedImage != nil {
                    Button(action: saveToPhotos) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    
                    Button(action: copyToClipboard) {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }
                    
                    ShareLink(item: Image(uiImage: loadedImage!), preview: SharePreview("Manga Page", image: Image(uiImage: loadedImage!))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(action: copyImageURL) {
                        Label("Copy Image URL", systemImage: "link")
                    }
                }
            }
            .alert("Image Action", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveAlertMessage)
            }
    }
    
    private func retryLoading() {
        // Clear cache for this specific URL
        KingfisherManager.shared.cache.removeImage(forKey: url)
        
        // Reset state and force reload
        loadingState = .idle
        reloadID = UUID()
    }
    
    private func saveToPhotos() {
        guard let image = loadedImage else { return }
        
        Task {
            do {
                let photosStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                
                switch photosStatus {
                case .authorized, .limited:
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                    await MainActor.run {
                        saveAlertMessage = "Image saved to Photos successfully!"
                        showingSaveAlert = true
                    }
                    
                case .denied, .restricted:
                    await MainActor.run {
                        saveAlertMessage = "Please grant permission to save images in Settings > Privacy & Security > Photos."
                        showingSaveAlert = true
                    }
                    
                case .notDetermined:
                    break
                    
                @unknown default:
                    break
                }
            } catch {
                await MainActor.run {
                    saveAlertMessage = "Failed to save image: \(error.localizedDescription)"
                    showingSaveAlert = true
                }
            }
        }
    }
    
    private func copyToClipboard() {
        guard let image = loadedImage else { return }
        
        UIPasteboard.general.image = image
        
        // Haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        saveAlertMessage = "Image copied to clipboard!"
        showingSaveAlert = true
    }
    
    private func copyImageURL() {
        UIPasteboard.general.string = url
        
        // Haptic feedback for better UX
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        saveAlertMessage = "Image URL copied to clipboard!"
        showingSaveAlert = true
    }
}

extension RetryableImage {
    @ViewBuilder
    private func ProgressOverlay(state: LoadingState, onRetry: @escaping () -> Void) -> some View {
        switch state {
        case .idle:
            EmptyView()
            
        case .loading(let progress):
            if progress > 0 && progress < 1 {
                ReaderImageProgress(progress: progress)
                    .frame(width: 50, height: 50)
            }
            
        case .loaded:
            EmptyView()
            
        case .failed:
            ReaderImageRetry(callback: onRetry)
        }
    }
}

private struct ReaderImageProgress: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.tint.opacity(0.3), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color.text, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .bold()
                .foregroundColor(.text)
        }
    }
}

private struct ReaderImageRetry: View {
    let callback: () -> Void
    
    var body: some View {
        Button(action: callback) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                
                Text("Retry")
                    .font(.caption)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appRed)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
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

//
//  ArtworkListView.swift
//  Alethia
//
//  Created by Angelo Carasig on 30/5/2025.
//

import SwiftUI
import Kingfisher

struct ArtworkListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: DetailsViewModel
    @State private var selectedIndex: Int = 0
    @State private var showingUpdateAlert = false
    @State private var coverToUpdate: Cover?
    @State private var scrollPosition: Int?
    
    private typealias CoverId = Int64
    private typealias Resolution = CGSize
    
    @State private var imageResolutions: [CoverId: Resolution] = [:]
    
    var covers: [Cover] {
        vm.details?.covers ?? []
    }
    
    var currentCover: Cover? {
        covers.indices.contains(selectedIndex) ? covers[selectedIndex] : nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderBar()
            
            // Carousel View
            TabView(selection: $selectedIndex) {
                ForEach(Array(covers.enumerated()), id: \.element.id) { index, cover in
                    CarouselCard(cover: cover)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedIndex)
            
            // Bottom Controls
            BottomControls()
        }
        .alert("Set as Active Cover?", isPresented: $showingUpdateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Set Active") {
                if let cover = coverToUpdate {
                    updateActiveCover(cover)
                }
            }
        } message: {
            Text("This will set the selected artwork as the active cover for this manga.")
        }
    }
    
    // MARK: - Header Bar
    @ViewBuilder
    private func HeaderBar() -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.text.opacity(0.7), .text.opacity(0.1))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("ARTWORK")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text("\(selectedIndex + 1) of \(covers.count)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.text)
            }
            
            Spacer()
            
            Menu {
                if let cover = currentCover {
                    ShareLink(item: URL(string: cover.url)!) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        // TODO: Save to photos
                    } label: {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        UIPasteboard.general.string = cover.url
                    } label: {
                        Label("Copy URL", systemImage: "link")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.text.opacity(0.7), .text.opacity(0.1))
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
        .padding(.vertical, Constants.Padding.regular)
    }
    
    // MARK: - Carousel Card
    @ViewBuilder
    private func CarouselCard(cover: Cover) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                KFImage(URL(string: cover.url))
                    .onSuccess { result in
                        if let coverId = cover.id {
                            imageResolutions[coverId] = result.image.size
                        }
                    }
                    .placeholder {
                        Color.tint.shimmer()
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width * 0.85)
                    .cornerRadius(Constants.Corner.Radius.panel)
                    .contextMenu {
                        ShareLink(item: URL(string: cover.url)!) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            // TODO: Save to photos
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                        
                        Button {
                            UIPasteboard.general.string = cover.url
                        } label: {
                            Label("Copy URL", systemImage: "link")
                        }
                    }
                
                // Image Info Display
                if let coverId = cover.id,
                   let info = imageResolutions[coverId] {
                    Text(String(format: "%d × %d", Int(info.width), Int(info.height)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, Constants.Padding.regular)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // Helper function to format file size
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Bottom Controls
    @ViewBuilder
    private func BottomControls() -> some View {
        VStack(spacing: Constants.Spacing.large) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Constants.Spacing.regular) {
                    ForEach(Array(covers.enumerated()), id: \.element.id) { index, cover in
                        ThumbnailView(
                            cover: cover,
                            isSelected: selectedIndex == index,
                            index: index
                        )
                        .padding(.horizontal, selectedIndex == index ? Constants.Padding.minimal : 0)
                        .pressable()
                        .onTapGesture {
                            withAnimation {
                                selectedIndex = index
                            }
                        }
                        .scrollTargetLayout()
                    }
                }
                .padding(.horizontal, Constants.Padding.screen)
                .padding(.vertical, Constants.Padding.screen)
            }
            .frame(height: 125) // Increased height for scaling
            .padding(.vertical, Constants.Padding.screen)
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .scrollClipDisabled() // Allow content to be visible outside scroll bounds
            .onChange(of: selectedIndex) { _, newValue in
                withAnimation {
                    scrollPosition = newValue
                }
            }
            
            // Action Buttons
            if let cover = currentCover {
                HStack(spacing: Constants.Spacing.large) {
                    Button {
                        if !cover.active {
                            coverToUpdate = cover
                            showingUpdateAlert = true
                        }
                    } label: {
                        Label(
                            cover.active ? "Active Cover" : "Set as Active",
                            systemImage: cover.active ? "checkmark.circle.fill" : "checkmark.circle"
                        )
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20).padding(.vertical, 12)    // Don't adjust these
                        .foregroundStyle(cover.active ? Color.secondary : Color.background)
                        .background(cover.active ? Color.secondary.opacity(0.2) : Color.text)
                        .clipShape(.capsule)
                    }
                    .disabled(cover.active)
                    
                    ShareLink(item: URL(string: cover.url)!) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Color.tint)
                            .clipShape(.circle)
                    }
                }
            }
        }
        .padding(.bottom, Constants.Padding.screen)
    }
    
    // MARK: - Thumbnail View
    @ViewBuilder
    private func ThumbnailView(cover: Cover, isSelected: Bool, index: Int) -> some View {
        KFImage(URL(string: cover.url))
            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 420, height: 420)))
            .placeholder { Color.tint.shimmer() }
            .resizable()
            .scaledToFill()
            .frame(width: 125 * (11/16), height: 125)
            .cornerRadius(Constants.Corner.Radius.card)
            .overlay(
                ZStack {
                    if cover == vm.activeCover {
                        Color.black.opacity(0.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .cornerRadius(Constants.Corner.Radius.card)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .padding(Constants.Padding.regular)
                    }
                    
                    // Number Badge
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                        .offset(x: 27.5, y: -47.5)
                }
            )
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func updateActiveCover(_ cover: Cover) {
        vm.updateMangaCover(cover)
        dismiss()
    }
}

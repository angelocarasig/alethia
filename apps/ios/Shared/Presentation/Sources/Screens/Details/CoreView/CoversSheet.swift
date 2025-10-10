//
//  CoversSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import SwiftUI
import Kingfisher

struct CoversSheet: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let primary: URL
    let covers: [URL]
    
    @State private var selectedCover: URL
    
    private var allCovers: [URL] {
        [primary] + covers.filter { $0 != primary }
    }
    
    init(title: String, primary: URL, covers: [URL]) {
        self.title = title
        self.primary = primary
        self.covers = covers
        self._selectedCover = State(initialValue: primary)
    }
    
    private var currentIndex: Int {
        allCovers.firstIndex(of: selectedCover) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // cover carousel with background
                ZStack {
                    // blurred background only in carousel area
                    KFImage(selectedCover)
                        .resizable()
                        .coverCache()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width, height: 500)
                        .clipped()
                        .blur(radius: 25)
                        .opacity(0.67)
                        .ignoresSafeArea(.container, edges: [.leading, .trailing])
                        .animation(.easeInOut(duration: 0.3), value: selectedCover)
                    
                    // main carousel content
                    ZStack(alignment: .bottom) {
                        TabView(selection: $selectedCover) {
                            ForEach(allCovers, id: \.self) { coverURL in
                                KFImage(coverURL)
                                    .placeholder { theme.colors.tint.shimmer() }
                                    .resizable()
                                    .coverCache()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
                                    .tag(coverURL)
                                    .containerRelativeFrame(.horizontal)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        
                        // counter overlay
                        HStack {
                            Spacer()
                            
                            Text("\(currentIndex + 1) / \(allCovers.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, dimensions.padding.regular)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .clipShape(.capsule)
                                .padding(dimensions.padding.screen)
                        }
                    }
                }
                .frame(height: 500)
                
                // controls below carousel
                ScrollView {
                    VStack(spacing: dimensions.spacing.large) {
                        navigationControls
                        actionButtons
                    }
                    .padding(dimensions.padding.screen)
                }
            }
            .navigationTitle("Covers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    @ViewBuilder
    private var navigationControls: some View {
        HStack(spacing: dimensions.spacing.regular) {
            // previous button
            Button {
                withAnimation {
                    if currentIndex > 0 {
                        selectedCover = allCovers[currentIndex - 1]
                    }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body)
                    .foregroundColor(currentIndex > 0 ? theme.colors.foreground : theme.colors.foreground.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(theme.colors.tint)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == 0)
            
            Spacer()
            
            // status badge
            statusBadge
            
            Spacer()
            
            // next button
            Button {
                withAnimation {
                    if currentIndex < allCovers.count - 1 {
                        selectedCover = allCovers[currentIndex + 1]
                    }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(currentIndex < allCovers.count - 1 ? theme.colors.foreground : theme.colors.foreground.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .background(theme.colors.tint)
                    .clipShape(Circle())
            }
            .disabled(currentIndex == allCovers.count - 1)
        }
        .padding(.top, dimensions.padding.regular)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if selectedCover == primary {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                Text("Primary Cover")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(theme.colors.accent)
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, 6)
            .background(theme.colors.accent.opacity(0.1))
            .clipShape(.capsule)
        } else {
            HStack(spacing: dimensions.spacing.minimal) {
                Image(systemName: "photo")
                    .font(.caption)
                Text("Alternative")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(theme.colors.foreground.opacity(0.6))
            .padding(.horizontal, dimensions.padding.regular)
            .padding(.vertical, 6)
            .background(theme.colors.foreground.opacity(0.1))
            .clipShape(.capsule)
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: dimensions.spacing.regular) {
            if selectedCover != primary {
                Button {
                    // TODO: set as primary
                } label: {
                    HStack(spacing: dimensions.spacing.regular) {
                        Image(systemName: "star.fill")
                            .font(.body)
                        
                        Text("Set as Primary Cover")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(theme.colors.accent)
                    .padding(dimensions.padding.screen)
                    .background(theme.colors.accent.opacity(0.1))
                    .cornerRadius(dimensions.cornerRadius.button)
                }
            }
            
            Button {
                // TODO: share
            } label: {
                HStack(spacing: dimensions.spacing.regular) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                    
                    Text("Share Cover")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(theme.colors.foreground)
                .padding(dimensions.padding.screen)
                .background(theme.colors.tint)
                .cornerRadius(dimensions.cornerRadius.button)
            }
        }
    }
}

#Preview("Multiple Covers") {
    CoversSheet(
        title: "Solo Leveling",
        primary: URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/84eb80c2-4cbe-4fc8-a3e0-b24bf8136473.jpg")!,
        covers: [
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/c09db588-bac1-4f6d-a5ec-73e890f4613e.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/5683da85-8f52-4b85-8818-94f8cc24b0d1.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/5972847b-e0a4-4346-8dd6-8f06839ee1a7.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/df0d4573-b26d-467f-8c3c-4aacb5757c56.jpg")!
        ]
    )
}

#Preview("Many Covers (37 total)") {
    CoversSheet(
        title: "Manga with Many Volumes",
        primary: URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/84eb80c2-4cbe-4fc8-a3e0-b24bf8136473.jpg")!,
        covers: [
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/c09db588-bac1-4f6d-a5ec-73e890f4613e.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/5683da85-8f52-4b85-8818-94f8cc24b0d1.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/5972847b-e0a4-4346-8dd6-8f06839ee1a7.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/df0d4573-b26d-467f-8c3c-4aacb5757c56.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/22b579ef-1f97-462c-8483-31a6d26a4ee3.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/03a38d35-df99-467d-89b5-5d56ad0e3ee5.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/c2e4f2f4-df56-455d-ac5d-9894ddbd3aba.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/9b2df5b2-9632-45b5-ae2e-b3e02c0ce68e.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/73fdfa73-2fe6-4893-a19b-d0d1d4551824.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/b12f8b37-d8f7-432c-bf6e-29422419be40.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/f1ab5b09-680f-4619-b9da-e533e070f7a9.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/d3043217-23cd-493d-87e4-abae67886374.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/2754672d-e642-48c5-bd70-0f5d5d285ff6.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/7fd09d46-f50b-41b4-b639-02c69ed018fe.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/cf8fd3f4-f6f4-4c38-aba7-75bfc14731be.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/9c4006de-2bec-44fb-9522-6e3b4ff29f49.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/e3c808a1-21b8-4955-8b37-ccd2c072119f.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/bd9a68ce-4d81-4abd-ac7b-1ab7bfa8b693.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/0d3339ab-35cb-4811-8f96-5d0d5e20e6ef.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/3382ad59-9159-457c-9ed5-489296aa96eb.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/b62a5812-d0e2-4b5d-a83c-bac19acce7d3.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/55bb9660-3ca9-4db3-8635-dbc0b89ebd7d.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/fb2a0cd8-0c72-48ef-97ff-a629478d79e8.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/74ff6ac9-4a42-4f19-90db-36ecc252edbe.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/877156c0-958b-45ea-8a70-bc849c80e365.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/c1185422-5685-4407-a482-08b621c2d368.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/3c2795ec-5db1-4f4e-b87c-15353bb2dff8.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/47bc99c1-774c-4423-8d27-47c8b1de8f13.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/2d50161f-e715-4e4f-86bd-d38772823b39.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/8712211a-c583-4875-ae0e-e065536d3da8.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/4f894450-143d-455d-9548-2b44ad06b112.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/7283d684-bcea-4ca2-b19e-19f47323c90d.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/dd67952b-3881-48ac-a725-764251d6886b.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/426242c4-b281-4f19-bb79-c4e15ab6bb24.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/2fffbe0f-a5c5-4365-a0ba-98e8431c71de.jpg")!,
            URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/d3e909b9-c667-48a5-beec-ac96f23fa228.jpg")!
        ]
    )
}

#Preview("Single Cover") {
    CoversSheet(
        title: "One Piece",
        primary: URL(string: "https://uploads.mangadex.org/covers/aa6c76f7-5f5f-46b6-a800-911145f81b9b/84eb80c2-4cbe-4fc8-a3e0-b24bf8136473.jpg")!,
        covers: []
    )
}

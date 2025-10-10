//
//  HeaderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI
import Domain
import Kingfisher

struct HeaderView: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var showArtwork: Bool = false
    @State private var showAlternativeTitles: Bool = false
    @State private var showCovers: Bool = false
    
    var cover: URL
    var title: String
    var alternativeTitles: [String]
    var authors: [String]
    var covers: [URL]
    
    var body: some View {
        VStack(alignment: .leading) {
            KFImage(cover)
                .placeholder { theme.colors.tint.shimmer() }
                .resizable()
                .framed(maxWidth: 200, maxHeight: 200)
                .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular, style: .continuous))
                .tappable {
                    if covers.count > 1 {
                        showCovers = true
                    } else {
                        showArtwork = true
                    }
                }
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .contextMenu { TitleContextMenu() }
                    .tappable {
                        if !alternativeTitles.isEmpty {
                            showAlternativeTitles = true
                        }
                    }
                
                Text(authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showArtwork) {
            ArtworkSheet()
        }
        .sheet(isPresented: $showAlternativeTitles) {
            AlternativeTitlesSheet(
                primaryTitle: title,
                alternativeTitles: alternativeTitles
            )
        }
        .sheet(isPresented: $showCovers) {
            CoversSheet(
                title: title,
                covers: covers,
                currentCover: cover
            )
        }
    }
    
    @ViewBuilder
    private func TitleContextMenu() -> some View {
        Section {
            Button {
                UIPasteboard.general.string = title
            } label: {
                Label("Copy Title", systemImage: "doc.on.doc")
            }
            
            Button {
                
            } label: {
                Label("Search Other Sources For This Title", systemImage: "magnifyingglass")
            }
        }
    }
}

// MARK: - Alternative Titles Sheet
private struct AlternativeTitlesSheet: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let primaryTitle: String
    let alternativeTitles: [String]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: dimensions.spacing.large) {
                    // primary title section
                    VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(theme.colors.appYellow)
                            
                            Text("PRIMARY TITLE")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(theme.colors.foreground.opacity(0.6))
                        }
                        
                        titleCard(
                            primaryTitle,
                            icon: "checkmark.seal.fill",
                            color: theme.colors.accent
                        )
                    }
                    
                    if !alternativeTitles.isEmpty {
                        Divider()
                        
                        // alternative titles section
                        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                            HStack {
                                Image(systemName: "character.book.closed")
                                    .font(.caption)
                                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                                
                                Text("ALTERNATIVE TITLES")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.colors.foreground.opacity(0.6))
                                
                                Spacer()
                                
                                Text("\(alternativeTitles.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.colors.accent)
                                    .padding(.horizontal, dimensions.padding.regular)
                                    .padding(.vertical, dimensions.padding.minimal)
                                    .background(theme.colors.accent.opacity(0.1))
                                    .clipShape(.capsule)
                            }
                            
                            VStack(spacing: dimensions.spacing.regular) {
                                ForEach(Array(alternativeTitles.enumerated()), id: \.offset) { index, altTitle in
                                    titleCard(
                                        altTitle,
                                        icon: "text.quote",
                                        color: theme.colors.foreground.opacity(0.6)
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Titles")
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
    private func titleCard(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: dimensions.spacing.regular) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = title
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                    .padding(dimensions.padding.regular)
                    .background(theme.colors.tint)
                    .clipShape(Circle())
            }
        }
        .padding(dimensions.padding.screen)
        .background(theme.colors.tint)
        .cornerRadius(dimensions.cornerRadius.button)
        .contextMenu {
            Button {
                UIPasteboard.general.string = title
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                // TODO: search for this title
            } label: {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}
// MARK: - Covers Sheet (Carousel - Redesigned)
private struct CoversSheet: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let covers: [URL]
    let currentCover: URL
    
    @State private var selectedCover: URL
    
    init(title: String, covers: [URL], currentCover: URL) {
        self.title = title
        self.covers = covers
        self.currentCover = currentCover
        self._selectedCover = State(initialValue: currentCover)
    }
    
    private var currentIndex: Int {
        covers.firstIndex(of: selectedCover) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // large preview with overlay counter
                ZStack(alignment: .bottom) {
                    TabView(selection: $selectedCover) {
                        ForEach(covers, id: \.self) { coverURL in
                            KFImage(coverURL)
                                .placeholder { theme.colors.tint.shimmer() }
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .tag(coverURL)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // counter overlay
                    HStack {
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(covers.count)")
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
                .frame(height: 500)
                
                ScrollView {
                    VStack(spacing: dimensions.spacing.large) {
                        // status and navigation
                        HStack(spacing: dimensions.spacing.regular) {
                            // navigation buttons
                            Button {
                                withAnimation {
                                    if currentIndex > 0 {
                                        selectedCover = covers[currentIndex - 1]
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
                            if selectedCover == currentCover {
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
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    if currentIndex < covers.count - 1 {
                                        selectedCover = covers[currentIndex + 1]
                                    }
                                }
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.body)
                                    .foregroundColor(currentIndex < covers.count - 1 ? theme.colors.foreground : theme.colors.foreground.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .background(theme.colors.tint)
                                    .clipShape(Circle())
                            }
                            .disabled(currentIndex == covers.count - 1)
                        }
                        .padding(.top, dimensions.padding.regular)
                        
                        // cover details card
                        VStack(alignment: .leading, spacing: dimensions.spacing.regular) {
                            // filename
                            HStack(spacing: dimensions.spacing.regular) {
                                Image(systemName: "doc.text")
                                    .font(.body)
                                    .foregroundColor(theme.colors.foreground.opacity(0.5))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Filename")
                                        .font(.caption)
                                        .foregroundColor(theme.colors.foreground.opacity(0.5))
                                    
                                    Text(selectedCover.lastPathComponent)
                                        .font(.subheadline)
                                        .foregroundColor(theme.colors.foreground)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(dimensions.padding.screen)
                        .background(theme.colors.tint)
                        .cornerRadius(dimensions.cornerRadius.button)
                        
                        // action buttons
                        VStack(spacing: dimensions.spacing.regular) {
                            if selectedCover != currentCover {
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
}

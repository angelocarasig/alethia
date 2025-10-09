//
//  +ChapterRow.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI
import Kingfisher
import Domain

struct ChapterRow: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    let chapter: Chapter
    
    var body: some View {
        HStack {
            icon
            info
            Spacer()
            download
        }
        .padding(.vertical, dimensions.padding.minimal)
        .opacity(chapter.finished ? 0.6 : 1.0)
    }
    
    @ViewBuilder
    private var icon: some View {
        KFImage(chapter.icon ?? URL(string: ""))
            .placeholder { theme.colors.tint.shimmer() }
            .resizable()
            .scaledToFit()
            .frame(dimensions.icon.chapter)
            .clipShape(.rect(cornerRadius: dimensions.cornerRadius.regular))
            .padding(.trailing, dimensions.padding.regular)
    }
    
    @ViewBuilder
    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Chapter \(chapter.number.toString())")
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(chapter.date.toRelativeString())
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                
                if chapter.date >= Calendar.current.date(byAdding: .day, value: -3, to: Date())! {
                    Text("NEW")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.vertical, dimensions.padding.minimal)
                        .padding(.horizontal, dimensions.padding.regular)
                        .background(theme.colors.alert)
                        .cornerRadius(dimensions.cornerRadius.regular)
                }
                
                if chapter.finished {
                    Text("Read")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.vertical, dimensions.padding.minimal)
                        .padding(.horizontal, dimensions.padding.regular)
                        .background(theme.colors.appOrange)
                        .cornerRadius(dimensions.cornerRadius.regular)
                }
            }
            .font(.caption)
            
            Text(chapter.title.isEmpty ? "Chapter \(chapter.number.toString())" : chapter.title)
                .lineLimit(2)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(chapter.scanlator)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if chapter.progress > 0 && chapter.progress != 1 {
                ProgressView(value: chapter.progress)
                    .tint(Color.accentColor)
                    .frame(height: 3)
                    .clipShape(.capsule)
            }
        }
    }
    
    @ViewBuilder
    private var download: some View {
        DownloadProgressButton()
            .frame(dimensions.icon.pill)
            .padding(.horizontal, dimensions.padding.regular)
    }
}

@available(*, deprecated, message: "Will be removed in a future version")
private struct DownloadProgressButton: View {
    @State private var progress: CGFloat = 0
    @State private var state: DownloadState = .idle
    
    private enum DownloadState {
        case idle
        case downloading
        case cancelled
        case completed
    }
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // background circle - only visible when downloading or cancelled
            Circle()
                .stroke(lineWidth: 2)
                .opacity(0.3)
                .foregroundColor(.gray)
                .opacity(state == .downloading || state == .cancelled ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: state)
            
            // progress circle - only visible when downloading
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundColor(.accentColor)
                .rotationEffect(Angle(degrees: -90))
                .opacity(state == .downloading ? 1 : 0)
            
            Button {
                handleButtonPress()
            } label: {
                Group {
                    switch state {
                    case .idle:
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    case .downloading:
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    case .cancelled:
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    case .completed:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .font(.title3)
                .animation(.easeInOut(duration: 0.2), value: state)
            }
        }
        .onReceive(timer) { _ in
            if state == .downloading {
                withAnimation(.linear(duration: 0.05)) {
                    progress += 1.0 / 60.0  // 60 steps over 3 seconds
                    
                    if progress >= 1.0 {
                        progress = 0
                        withAnimation(.easeInOut(duration: 0.3)) {
                            state = .completed
                        }
                    }
                }
            }
        }
    }
    
    private func handleButtonPress() {
        switch state {
        case .idle:
            // start download
            state = .downloading
            progress = 0
        case .downloading:
            // cancel download
            withAnimation(.easeInOut(duration: 0.2)) {
                state = .cancelled
                progress = 0
            }
        case .cancelled:
            // reset to idle
            withAnimation(.easeInOut(duration: 0.2)) {
                state = .idle
            }
        case .completed:
            // optionally reset from completed state
            withAnimation(.easeInOut(duration: 0.2)) {
                state = .idle
                progress = 0
            }
        }
    }
}

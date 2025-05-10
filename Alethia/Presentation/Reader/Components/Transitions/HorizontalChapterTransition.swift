//
//  HorizontalChapterTransition.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI
import Combine

private struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

struct HorizontalChapterTransition: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    let direction: TransitionDirection
    let chapter: ChapterExtended
    let onWillLoad: () -> Void
    let onDidLoad: () -> Void
    
    @State private var hasTriggeredLoad: Lock = .unlocked
    @State private var offsetSubject = PassthroughSubject<CGFloat, Never>()
    @State private var offsetCancellable: AnyCancellable?
    
    private var chapterIndex: Int? {
        vm.chapters.firstIndex { $0.chapter.id == chapter.chapter.id }
    }
    
    private var targetIndex: Int? {
        guard let i = chapterIndex else { return nil }
        return direction == .previous ? i + 1 : i - 1
    }
    
    private var targetChapter: ChapterExtended? {
        guard let i = targetIndex, vm.chapters.indices.contains(i) else { return nil }
        return vm.chapters[i]
    }
    
    private var titleText: String {
        direction == .previous ? "Now Reading" : "End of Chapter"
    }
    
    private var buttonText: String {
        direction == .previous ? "Previous Chapter" : "Next Chapter"
    }
    
    private var missingText: String {
        "There is no \(direction == .previous ? "previous" : "next") chapter."
    }
    
    private var threshold: CGFloat {
        direction == .previous ? 150 : 400
    }
    
    var body: some View {
        ContentView()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ViewOffsetKey.self,
                                    value: geo.frame(in: .global).minX)
                }
            )
            .onPreferenceChange(ViewOffsetKey.self) { raw in
                offsetSubject.send(raw)
            }
            .onAppear {
                vm.onHorizontalPageTransition = true
                
                offsetCancellable = offsetSubject
                    .sink { offset in
                        guard let idx = chapterIndex,
                              hasTriggeredLoad == .unlocked
                        else { return }
                        let passed = direction == .previous
                        ? offset > threshold
                        : offset < threshold
                        if passed {
                            hasTriggeredLoad = .locked
                            onWillLoad()
                            Task {
                                try? await withThrowingTimeout(seconds: 1) {
                                    await vm.loadChapter(
                                        at: idx + (direction == .previous ? 1 : -1)
                                    )
                                    onDidLoad()
                                }
                            }
                        }
                    }
            }
            .onDisappear {
                vm.onHorizontalPageTransition = false
                
                offsetCancellable?.cancel()
            }
    }
    
    @ViewBuilder
    private func ContentView() -> some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 8) {
                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Text(chapter.chapter.toString())
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(chapter.scanlator.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let target = targetChapter, let idx = chapterIndex {
                Button {
                    Task {
                        await vm.loadChapter(
                            at: idx + (direction == .previous ? 1 : -1)
                        )
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(buttonText)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(target.chapter.toString())
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                Text(target.scanlator.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding()
                .background(Color.tint.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Text(missingText)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

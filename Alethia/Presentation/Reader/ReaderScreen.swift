//
//  ReaderScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import SwiftUI

struct ReaderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ReaderViewModel
    
    @State private var position: ScrollPosition = .init(id: 0, anchor: .top)
    
    init(
        title: String,
        orientation: Orientation,
        startingChapter: Chapter,
        chapters: [ChapterExtended]
    ) {
        _vm = StateObject(
            wrappedValue: ReaderViewModel(
                title: title,
                orientation: orientation,
                startingChapter: startingChapter,
                chapters: chapters
            )
        )
    }
    
    var body: some View {
        VerticalReader()
            .edgesIgnoringSafeArea(.vertical)
            .onDisappear { vm.reset() }
            .environmentObject(vm)
    }
}

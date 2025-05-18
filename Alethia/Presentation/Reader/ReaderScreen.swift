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
            .statusBar(hidden: true)                // hides status bar (time/battery etc)
            .edgesIgnoringSafeArea(.vertical)       // shows content only
            .toolbar(.hidden, for: .tabBar)         // hides bottom tabbar
            .navigationBarBackButtonHidden()        // hides navbar
            .onDisappear { vm.reset() }
            .onChange(of: vm.shouldDismissReader) {
                if vm.shouldDismissReader {
                    dismiss()
                }
            }
            .environmentObject(vm)
    }
}

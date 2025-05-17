//
//  ReaderScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import SwiftUI

struct ReaderScreen: View {
    @StateObject private var vm: ReaderViewModel
    
    init(
        title: String,
        orientation: Orientation,
        startChapter: ChapterExtended,
        chapters: [ChapterExtended]
    ) {
        self._vm = StateObject(
            wrappedValue: ReaderViewModel(
                title: title,
                orientation: orientation,
                startChapter: startChapter,
                chapters: chapters
            )
        )
    }
    
    var body: some View {
        VerticalReader()
            .environmentObject(vm)
    }
}

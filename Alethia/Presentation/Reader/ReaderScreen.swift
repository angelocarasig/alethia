//
//  ReaderScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import SwiftUI

struct ReaderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ReaderViewModel
    
    @State private var position: ScrollPosition = .init(id: 0, anchor: .top)
    
    init(chapters: [ChapterExtended], currentChapterIndex: Int) {
        _vm = StateObject(
            wrappedValue: ReaderViewModel(
                chapters: chapters,
                currentChapterIndex: currentChapterIndex
            )
        )
    }
    
    var body: some View {
        VStack {
            if vm.chapterLoaded {
                VerticalReader()
            }
        }
        .environmentObject(vm)
        .edgesIgnoringSafeArea(.top)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden()
    }
}

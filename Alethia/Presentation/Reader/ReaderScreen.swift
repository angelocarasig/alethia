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
    
    init(title: String, chapters: [ChapterExtended], currentChapterIndex: Int) {
        _vm = StateObject(
            wrappedValue: ReaderViewModel(
                title: title,
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
        .onTapGesture {
            withAnimation {
                vm.showOverlay.toggle()
            }
        }
        .overlay(ReaderOverlay())
        .environmentObject(vm)
        .edgesIgnoringSafeArea(.top)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!vm.showOverlay)
        .navigationBarBackButtonHidden()
    }
}

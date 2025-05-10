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
    
    init(
        title: String,
        orientation: Orientation,
        chapters: [ChapterExtended],
        currentChapterIndex: Int
    ) {
        _vm = StateObject(
            wrappedValue: ReaderViewModel(
                title: title,
                orientation: orientation,
                chapters: chapters,
                currentChapterIndex: currentChapterIndex
            )
        )
    }
    
    var body: some View {
        VStack {
            if vm.chapterLoaded.boolValue {
                switch vm.orientation {
                case .Infinite, .Vertical:
                    VerticalReader()
                case .LeftToRight, .RightToLeft:
                    HorizontalReader()
                }
            }
            else if vm.errorMessage != nil {
                Text("Error: \(vm.errorMessage!)")
            }
            else {
                Text("Loading Chapter...")
            }
        }
        .onTapGesture {
            guard vm.chapterLoaded.boolValue else { return }
            
            withAnimation {
                vm.showOverlay.toggle()
            }
        }
        .animation(.easeInOut, value: vm.chapterLoaded)
        .overlay(Overlay())
        .environmentObject(vm)
        .edgesIgnoringSafeArea(.top)
        .toolbar(.hidden, for: .tabBar)
        .statusBarHidden(!vm.showOverlay && vm.chapterLoaded.boolValue)
        .navigationBarBackButtonHidden()
    }
    
    @ViewBuilder
    private func Overlay() -> some View {
        ZStack {
            ReaderOverlay()
            
            ReaderNotificationBanner(message: vm.showNotificationBanner)
        }
    }
}

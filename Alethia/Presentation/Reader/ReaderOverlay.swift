//
//  ReaderOverlay.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI

struct ReaderOverlay: View {
    @EnvironmentObject private var vm: ReaderViewModel
    @Environment(\.dismiss) private var dismiss
    
    var chapter: ChapterExtended? {
        vm.currentPage?.getUnderlyingChapter(chapters: vm.chapters)
    }
    
    var totalPages: Int {
        vm.pages.filter { $0.chapterIndex == vm.currentPage?.chapterIndex }.count
    }
    
    var body: some View {
        if vm.showOverlay {
            VStack {
                TopSection()
                
                Spacer()
                
                BottomSection()
            }
        }
    }
    
    @ViewBuilder
    private func TopSection() -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(vm.mangaTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(vm.activeChapter?.chapter.toString() ?? "Loading Page...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.bar)
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private func BottomSection() -> some View {
        VStack {
            HStack {
                Button(action: vm.goToFirstPageInChapter) {
                    Image(systemName: "chevron.left")
                }
                .padding(.horizontal, 15)
                
                if totalPages > 1 {
                    Slider(
                        value: Binding<Double>(
                            get: { Double(vm.currentPage?.pageNumber ?? -1) },
                            set: { newValue in
                                vm.scrolledFromSlider = true
                                vm.currentPage = vm.pages.first(where: { $0.pageNumber == Int(newValue) })
                            }
                        ),
                        in: 1...Double(max(1, totalPages)),
                        step: 1
                    )
                }
                else {
                    Spacer()
                }
                
                Button(action: vm.goToLastPageInChapter) {
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal, 15)
            }
            
            Text("Page \(vm.currentPage?.pageNumber ?? -1) of \(totalPages)")
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .cornerRadius(20)
        .padding()
    }
}

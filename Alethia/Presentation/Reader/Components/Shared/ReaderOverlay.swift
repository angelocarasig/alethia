//
//  ReaderOverlay.swift
//  Alethia
//
//  Created by Angelo Carasig on 23/5/2025.
//

import SwiftUI
import Kingfisher

struct ReaderOverlay: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vm: ReaderViewModel
    
    var body: some View {
        if vm.showControls {
            VStack {
                TopSection()
                TopIslandButtons()
                
                Spacer()
                
                BottomSection()
            }
        }
    }
}

// MARK: Top Section
extension ReaderOverlay {
    @ViewBuilder
    private func TopSection() -> some View {
        HStack(spacing: Constants.Spacing.regular) {
            KFImage(URL(filePath: vm.currentChapter.source?.icon ?? ""))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text(vm.mangaTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(vm.currentPage?.underlyingChapter.chapter.toString() ?? "Loading Page...")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button {
                vm.updateChapterProgress(didCompleteChapter: false) {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            .padding(.trailing, Constants.Padding.regular)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Constants.Padding.minimal)
        .padding(.bottom, Constants.Padding.regular)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .padding(.top, 50) // Top offset
    }
    
    @ViewBuilder
    private func TopIslandButtons() -> some View {
        HStack {
            Button {
                vm.toggleOrientation()
            } label: {
                Image(systemName: vm.orientation.image)
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.5))
                    .clipShape(.circle)
            }
            
            Spacer()
            
            NavigationLink(destination: EmptyView()) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(Color.black.opacity(0.5))
                    .clipShape(.circle)
            }
        }
        .padding(.horizontal, Constants.Padding.screen)
    }
}


// MARK: Bottom Section
extension ReaderOverlay {
    @ViewBuilder
    private func BottomSection() -> some View {
        VStack {
            HStack {
                Button {
                    
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Constants.Padding.screen)
                
                if vm.totalPages > 1 {
                    Slider(
                        value: Binding<Double>(
                            get: { Double(vm.currentPage?.pageNumber ?? .min) },
                            set: { newValue in
                                if case let .loaded(pages) = vm.state,
                                   let newPage = pages.first(where: { $0.pageNumber == Int(newValue) } )
                                {
                                    vm.didScrollScrubber = true
                                    vm.updateCurrentPage(page: newPage)
                                }
                            }
                        ),
                        in: 1...Double(max(1, vm.totalPages)),
                        step: 1
                    )
                }
                else {
                    Spacer()
                }
                
                Button {
                    
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Constants.Padding.screen)
            }
            
            Text("Page \(vm.currentPage?.pageNumber ?? -1) of \(vm.totalPages)")
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding(Constants.Padding.regular)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .cornerRadius(Constants.Corner.Radius.panel)
        .padding()
    }
}

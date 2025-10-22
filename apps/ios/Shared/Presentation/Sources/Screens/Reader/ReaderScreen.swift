//
//  ReaderScreen.swift
//  Presentation
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI
import Domain
import Reader

struct ReaderScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    @State private var vm: ReaderViewModel
    @State private var showOverlay = true
    @State private var isSliding = false
    @State private var sliderValue: Double = 0
    
    init(chapters: [Chapter], startingChapterSlug: String) {
        self._vm = State(
            initialValue: ReaderViewModel(
                chapters: chapters,
                startingChapterSlug: startingChapterSlug
            )
        )
    }
    
    var body: some View {
        ZStack {
            if let coordinator = vm.coordinator {
                ReaderView(
                    dataSource: vm.dataSource,
                    startingChapterId: vm.startingChapterId,
                    ordering: .index,
                    configuration: ReaderConfiguration(
                        backgroundColor: theme.colors.background.uiColor,
                        showsScrollIndicator: false,
                        loadThreshold: 0.8,
                        readingMode: vm.readingMode
                    ),
                    coordinator: coordinator
                )
                .ignoresSafeArea()
                
                if showOverlay {
                    overlayControls(coordinator: coordinator)
                }
            } else {
                loadingView
            }
        }
        .statusBarHidden(!showOverlay)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .bottomBar)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showOverlay.toggle()
            }
        }
        .onAppear {
            vm.setupCoordinator()
        }
        .onChange(of: vm.coordinator?.currentPage) { _, newPage in
            if !isSliding, let newPage = newPage {
                sliderValue = Double(newPage)
            }
        }
        .onChange(of: vm.coordinator?.currentChapter) { _, _ in
            if !isSliding {
                sliderValue = Double(vm.coordinator?.currentPage ?? 0)
            }
        }
    }
}

// MARK: - Overlay Controls
extension ReaderScreen {
    @ViewBuilder
    private func overlayControls(coordinator: ReaderCoordinator<AlethiaReaderDataSource>) -> some View {
        VStack(spacing: 0) {
            topBar(coordinator: coordinator)
            Spacer()
            bottomBar(coordinator: coordinator)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func topBar(coordinator: ReaderCoordinator<AlethiaReaderDataSource>) -> some View {
        HStack(alignment: .top, spacing: dimensions.spacing.regular) {
            // close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
            
            // chapter info
            if let chapter = vm.currentChapter {
                VStack(spacing: 4) {
                    Text("Chapter \(Int(chapter.number))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Page \(coordinator.currentPage + 1) of \(coordinator.totalPages)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.regular)
                .background(.ultraThinMaterial, in: Capsule())
            }
            
            Spacer()
            
            // reading mode menu
            Menu {
                Section("Reading Mode") {
                    Button {
                        vm.updateReadingMode(.infinite)
                    } label: {
                        Label("Infinite Scroll", systemImage: vm.readingMode == .infinite ? "checkmark" : "")
                    }
                    
                    Button {
                        vm.updateReadingMode(.vertical)
                    } label: {
                        Label("Vertical", systemImage: vm.readingMode == .vertical ? "checkmark" : "")
                    }
                    
                    Button {
                        vm.updateReadingMode(.leftToRight)
                    } label: {
                        Label("Left to Right", systemImage: vm.readingMode == .leftToRight ? "checkmark" : "")
                    }
                    
                    Button {
                        vm.updateReadingMode(.rightToLeft)
                    } label: {
                        Label("Right to Left", systemImage: vm.readingMode == .rightToLeft ? "checkmark" : "")
                    }
                }
            } label: {
                Image(systemName: "text.alignleft")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }
    
    @ViewBuilder
    private func bottomBar(coordinator: ReaderCoordinator<AlethiaReaderDataSource>) -> some View {
        VStack(spacing: dimensions.spacing.screen) {
            // page slider
            pageSlider(coordinator: coordinator)
            
            // chapter navigation
            chapterNavigation(coordinator: coordinator)
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.bottom, dimensions.padding.screen)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .allowsHitTesting(false)
        )
    }
    
    @ViewBuilder
    private func pageSlider(coordinator: ReaderCoordinator<AlethiaReaderDataSource>) -> some View {
        HStack(spacing: dimensions.spacing.regular) {
            // current page indicator
            Text("\(coordinator.currentPage + 1)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            
            // slider
            if coordinator.totalPages > 1 {
                Slider(
                    value: $sliderValue,
                    in: 0...Double(max(1, coordinator.totalPages - 1)),
                    step: 1,
                    onEditingChanged: { editing in
                        isSliding = editing
                        if !editing {
                            vm.jumpToPage(Int(sliderValue))
                        }
                    }
                )
                .tint(.white)
                .disabled(coordinator.isScrolling || coordinator.isLoadingChapter)
                .opacity(coordinator.isScrolling ? 0.5 : 1.0)
            } else {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 4)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .fill(.white.opacity(0.3))
                    }
            }
            
            // total pages indicator
            Text("\(coordinator.totalPages)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(width: 40)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }
    
    @ViewBuilder
    private func chapterNavigation(coordinator: ReaderCoordinator<AlethiaReaderDataSource>) -> some View {
        HStack(spacing: dimensions.spacing.large) {
            // previous chapter button
            Button {
                vm.previousChapter()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(vm.hasPreviousChapter ? .white : .white.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .background(
                        vm.hasPreviousChapter
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(.ultraThinMaterial.opacity(0.5))
                    )
                    .clipShape(Circle())
            }
            .disabled(!vm.hasPreviousChapter)
            
            Spacer()
            
            // chapter info
            if let chapter = vm.currentChapter {
                VStack(spacing: 4) {
                    Text("Chapter \(Int(chapter.number))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("of \(vm.totalChapters)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.regular)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.horizontal, dimensions.padding.screen)
                    .padding(.vertical, dimensions.padding.regular)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            
            Spacer()
            
            // next chapter button
            Button {
                vm.nextChapter()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(vm.hasNextChapter ? .white : .white.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .background(
                        vm.hasNextChapter
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(.ultraThinMaterial.opacity(0.5))
                    )
                    .clipShape(Circle())
            }
            .disabled(!vm.hasNextChapter)
        }
    }
}

// MARK: - Loading View
extension ReaderScreen {
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: dimensions.spacing.large) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading chapter...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(dimensions.padding.screen * 2)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: dimensions.cornerRadius.button))
        }
    }
}

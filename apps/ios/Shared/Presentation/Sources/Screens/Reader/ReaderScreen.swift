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
    @Environment(\.dismiss) var dismiss
    @Environment(\.dimensions) var dimensions
    @Environment(\.theme) var theme
    @Environment(\.haptics) var haptics
    
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
            readerContent
            
            if showOverlay {
                if let coordinator = vm.coordinator {
                    ReaderOverlayView(
                        vm: vm,
                        coordinator: coordinator,
                        showOverlay: $showOverlay,
                        isSliding: $isSliding,
                        sliderValue: $sliderValue
                    )
                } else {
                    loadingOverlay
                }
            }
        }
        .statusBarHidden(!showOverlay)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .toolbarVisibility(.hidden, for: .bottomBar)
        .onTapGesture {
            withAnimation(.smooth(duration: 0.3)) {
                showOverlay.toggle()
            }
            haptics.impact(.light)
        }
        .onAppear {
            vm.setupCoordinator()
        }
        .onChange(of: vm.coordinator?.currentPage) { _, newPage in
            if !isSliding, let newPage = newPage {
                withAnimation(.smooth(duration: 0.2)) {
                    sliderValue = Double(newPage)
                }
            }
        }
        .onChange(of: vm.coordinator?.currentChapter) { _, _ in
            if !isSliding {
                withAnimation(.smooth(duration: 0.2)) {
                    sliderValue = Double(vm.coordinator?.currentPage ?? 0)
                }
            }
        }
    }
}

// MARK: - Main Content
extension ReaderScreen {
    @ViewBuilder
    private var readerContent: some View {
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
        } else {
            theme.colors.background.ignoresSafeArea()
        }
    }
}

// MARK: - Overlay Component
private struct ReaderOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.haptics) private var haptics
    
    let vm: ReaderViewModel
    let coordinator: ReaderCoordinator<AlethiaReaderDataSource>
    
    @Binding var showOverlay: Bool
    @Binding var isSliding: Bool
    @Binding var sliderValue: Double
    
    var body: some View {
        VStack(spacing: 0) {
            topOverlay
            Spacer()
            bottomOverlay
        }
    }
    
    @ViewBuilder
    private var topOverlay: some View {
        HStack(alignment: .center, spacing: dimensions.spacing.large) {
            closeButton
            
            Spacer()
            
            if let chapter = vm.currentChapter {
                chapterInfoDisplay(
                    chapter: chapter,
                    currentPage: coordinator.currentPage,
                    totalPages: coordinator.totalPages
                )
            }
            
            Spacer()
            
            readingModeButton
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
        .padding(.bottom, dimensions.padding.screen)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var bottomOverlay: some View {
        VStack(spacing: dimensions.spacing.screen) {
            pageSliderControl
            chapterNavigationControl
        }
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.top, dimensions.padding.screen)
        .padding(.bottom, dimensions.padding.screen)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var closeButton: some View {
        Button {
            haptics.impact(.medium)
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(.circle)
                .contentShape(.circle)
        }
    }
    
    @ViewBuilder
    private func chapterInfoDisplay(chapter: Chapter, currentPage: Int, totalPages: Int) -> some View {
        VStack(spacing: 3) {
            Text("Chapter \(Int(chapter.number))")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("\(currentPage + 1) / \(totalPages)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular + 2)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
    }
    
    @ViewBuilder
    private var readingModeButton: some View {
        Menu {
            ForEach(ReaderScreen.ReadingModeOption.allCases, id: \.self) { option in
                Button {
                    haptics.impact(.light)
                    vm.updateReadingMode(option.mode)
                } label: {
                    if vm.readingMode == option.mode {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            Image(systemName: "text.alignleft")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(.circle)
                .contentShape(.circle)
        }
    }
    
    @ViewBuilder
    private var pageSliderControl: some View {
        HStack(spacing: dimensions.spacing.large) {
            pageNumberLabel(coordinator.currentPage + 1)
            
            if coordinator.totalPages > 1 {
                pageSlider
            } else {
                staticSliderTrack
            }
            
            pageNumberLabel(coordinator.totalPages)
        }
    }
    
    @ViewBuilder
    private func pageNumberLabel(_ page: Int) -> some View {
        Text("\(page)")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .monospacedDigit()
            .frame(minWidth: 36)
            .padding(.vertical, dimensions.padding.regular)
            .padding(.horizontal, dimensions.padding.regular + 2)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
    }
    
    @ViewBuilder
    private var pageSlider: some View {
        Slider(
            value: $sliderValue,
            in: 0...Double(max(1, coordinator.totalPages - 1)),
            step: 1,
            onEditingChanged: { editing in
                isSliding = editing
                haptics.impact(.light)
                
                if !editing {
                    haptics.impact(.medium)
                }
            }
        )
        .tint(.white)
        .disabled(coordinator.isScrolling || coordinator.isLoadingChapter)
        .opacity(coordinator.isScrolling ? 0.5 : 1.0)
        .animation(.smooth(duration: 0.2), value: coordinator.isScrolling)
        .onChange(of: sliderValue) { _, newValue in
            if isSliding {
                vm.jumpToPage(Int(newValue))
            }
        }
    }
    
    @ViewBuilder
    private var staticSliderTrack: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .frame(height: 4)
            .overlay {
                Capsule()
                    .fill(.white.opacity(0.3))
            }
    }
    
    @ViewBuilder
    private var chapterNavigationControl: some View {
        HStack(spacing: dimensions.spacing.large) {
            chapterNavigationButton(
                direction: .previous,
                isEnabled: vm.hasPreviousChapter
            ) {
                vm.previousChapter()
            }
            
            Spacer()
            
            if let chapter = vm.currentChapter {
                chapterProgressDisplay(chapter: chapter)
            } else {
                chapterLoadingIndicator
            }
            
            Spacer()
            
            chapterNavigationButton(
                direction: .next,
                isEnabled: vm.hasNextChapter
            ) {
                vm.nextChapter()
            }
        }
    }
    
    @ViewBuilder
    private func chapterNavigationButton(
        direction: ReaderScreen.NavigationDirection,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            haptics.impact(.medium)
            action()
        } label: {
            Image(systemName: direction.icon)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.3))
                .frame(width: 52, height: 52)
                .background(
                    isEnabled
                        ? AnyShapeStyle(.ultraThinMaterial)
                        : AnyShapeStyle(.ultraThinMaterial.opacity(0.5))
                )
                .clipShape(.circle)
                .contentShape(.circle)
        }
        .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private func chapterProgressDisplay(chapter: Chapter) -> some View {
        VStack(spacing: 3) {
            Text("Chapter \(Int(chapter.number))")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("of \(vm.totalChapters)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, dimensions.padding.screen)
        .padding(.vertical, dimensions.padding.regular + 2)
        .background(.ultraThinMaterial)
        .clipShape(.capsule)
    }
    
    @ViewBuilder
    private var chapterLoadingIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .padding(.horizontal, dimensions.padding.screen)
            .padding(.vertical, dimensions.padding.regular + 2)
            .background(.ultraThinMaterial)
            .clipShape(.capsule)
    }
}

// MARK: - Supporting Types
extension ReaderScreen {
    enum ReadingModeOption: CaseIterable {
        case infinite
        case vertical
        case leftToRight
        case rightToLeft
        
        var title: String {
            switch self {
            case .infinite: return "Infinite Scroll"
            case .vertical: return "Vertical"
            case .leftToRight: return "Left to Right"
            case .rightToLeft: return "Right to Left"
            }
        }
        
        var mode: ReadingMode {
            switch self {
            case .infinite: return .infinite
            case .vertical: return .vertical
            case .leftToRight: return .leftToRight
            case .rightToLeft: return .rightToLeft
            }
        }
    }
    
    enum NavigationDirection {
        case previous
        case next
        
        var icon: String {
            switch self {
            case .previous: return "chevron.left"
            case .next: return "chevron.right"
            }
        }
    }
}

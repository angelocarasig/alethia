struct VerticalReaderRepresentable: UIViewRepresentable {
    var startChapter: Chapter
    var chapters: [Chapter]
    @ObservedObject var viewModel: ReaderViewModel
    
    func makeUIView(context: Context) -> VerticalReader {
        // Reset preloaded chapters in view model to ensure we can always navigate to any chapter
        let readerView = VerticalReader(
            startChapter: startChapter,
            chapters: chapters,
            orientation: viewModel.orientation
        )
        readerView.delegate = context.coordinator
        return readerView
    }
    
    func updateUIView(_ uiView: VerticalReader, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VerticalReaderDelegate {
        private var parent: VerticalReaderRepresentable
        
        init(_ parent: VerticalReaderRepresentable) {
            self.parent = parent
        }
        
        func didScrollToPage(_ page: Page) {
            parent.viewModel.currentPage = page
            
            // Update progress
            if let index = parent.chapters.firstIndex(where: { $0.id == page.chapter.id }) {
                let totalChapters = parent.chapters.count
                let chapterProgress = Double(index) / Double(totalChapters)
                parent.viewModel.progress = chapterProgress
            }
        }
        
        func didFinishChapter(_ chapter: Chapter) {
            // Optional: Trigger any actions when a chapter is completed
            print("Finished chapter: \(chapter.toString())")
        }
        
        func didChangeChapter(from previousChapter: Chapter, to newChapter: Chapter) {
            // Publish the chapter change to the view model
            print("Changed from chapter \(previousChapter.number) to \(newChapter.number)")
            
            // Notify the view model of the chapter change
            parent.viewModel.notifyChapterChange(from: previousChapter, to: newChapter)
        }
        
        func didStartScrolling() {
            // Hide controls when user scrolls
            parent.viewModel.hideNavigationBar()
        }
    }
}

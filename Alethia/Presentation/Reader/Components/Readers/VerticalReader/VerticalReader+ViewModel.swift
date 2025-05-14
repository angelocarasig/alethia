final class ReaderViewModel: ObservableObject {
    @Published var currentPage: Page?
    @Published var progress: Double = 0.0
    @Published var isNavigationBarHidden = true
    @Published var notificationMessage: String? = nil
    @Published var orientation: Orientation
    
    private var cancellables = Set<AnyCancellable>()
    
    init(orientation: Orientation) {
        self.orientation = orientation
        
        // Toggle navigation bar visibility on tap
        $currentPage
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.isNavigationBarHidden = true
            }
            .store(in: &cancellables)
    }
    
    func toggleNavigationBarVisibility() {
        isNavigationBarHidden.toggle()
    }
    
    func hideNavigationBar() {
        // Only animate if it's currently showing
        if !isNavigationBarHidden {
            withAnimation(.easeOut(duration: 0.2)) {
                isNavigationBarHidden = true
            }
        }
    }
    
    func notifyChapterChange(from previous: Chapter, to new: Chapter) {
        // Print the chapter change
        print("📚 CHAPTER CHANGED: from Chapter \(previous.number) to Chapter \(new.number)")
        
        // Show notification banner with chapter information
        let message = new.number > previous.number ? 
                     "Chapter \(new.number.toString()) ↓" : 
                     "Chapter \(new.number.toString()) ↑"
        showNotificationBanner(message: message)
    }
    
    private func showNotificationBanner(message: String) {
        // Show the notification with a smooth animation
        withAnimation(.easeOut(duration: 0.3)) {
            notificationMessage = message
        }
        
        // Schedule the hide after 2.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    notificationMessage = nil
                }
            }
        }
    }
}
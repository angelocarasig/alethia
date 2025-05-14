struct Page: Identifiable, Equatable, Hashable {
    static func == (lhs: Page, rhs: Page) -> Bool {
        lhs.id == rhs.id
    }
    
    let id = UUID()
    
    let number: Double
    let url: String
    let chapter: Chapter
    
    let isFirstPage: Bool
    let isLastPage: Bool
    
    init(number: Double, url: String, chapter: Chapter, isFirstPage: Bool, isLastPage: Bool) {
        self.number = number
        self.url = url
        self.chapter = chapter
        self.isFirstPage = isFirstPage
        self.isLastPage = isLastPage
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
//
//  ReaderView.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import SwiftUI

// MARK: - SwiftUI Wrapper

public struct ReaderView<DataSource: ReaderDataSource>: UIViewControllerRepresentable {
    
    private let dataSource: DataSource
    private let startingChapterId: DataSource.Chapter.ID
    private let ordering: ChapterOrdering<DataSource.Chapter>
    private let configuration: ReaderConfiguration
    @Bindable private var coordinator: ReaderCoordinator<DataSource>
    
    public init(
        dataSource: DataSource,
        startingChapterId: DataSource.Chapter.ID,
        ordering: ChapterOrdering<DataSource.Chapter> = .index,
        configuration: ReaderConfiguration = .default,
        coordinator: ReaderCoordinator<DataSource>
    ) {
        self.dataSource = dataSource
        self.startingChapterId = startingChapterId
        self.ordering = ordering
        self.configuration = configuration
        self.coordinator = coordinator
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        // create type-erased versions
        let anyDataSource = AnyReaderDataSource(dataSource)
        let anyOrdering = AnyChapterOrdering(ordering)
        let anyStartingId = ChapterID(startingChapterId)
        
        let reader = Reader(
            dataSource: anyDataSource,
            startingChapterId: anyStartingId,
            ordering: anyOrdering,
            configuration: configuration
        )
        
        // attach coordinator with typed data source
        coordinator.attach(reader, dataSource: dataSource)
        
        // return as UIViewController to hide Reader type
        return reader
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard let reader = uiViewController as? Reader else { return }
        reader.updateConfiguration(configuration)
    }
}

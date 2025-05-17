//
//  +DataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Foundation
import AsyncDisplayKit
import OrderedCollections
import Combine

struct VerticalReaderDataSource {
    var sections: OrderedSet<Slug> = []
    private var items: [Slug: [ReaderPanel]] = [:]
    
    func itemIdentifier(for path: IndexPath) -> ReaderPanel? {
        sections
            .getOrNil(path.section)
            .flatMap { items[$0]?.getOrNil(path.item) }
    }
    
    mutating func appendSections(_ sections: [String]) {
        self.sections
            .append(contentsOf: sections)
    }
    
    mutating func appendItems(_ newItems: [ReaderPanel], to section: String) {
        items.updateValue(newItems, forKey: section)
    }
    
    func getSection(at idx: Int) -> String? {
        sections
            .getOrNil(idx)
    }
    
    var numberOfSections: Int {
        sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        getSection(at: section)
            .flatMap { items[$0]?.count } ?? 0
    }
    
    func itemIdentifiers(inSection section: String) -> [ReaderPanel] {
        items[section] ?? []
    }
}

extension VerticalReaderController: ASCollectionDataSource {
    func numberOfSections(in _: ASCollectionNode) -> Int {
        dataSource
            .numberOfSections
    }
    
    func collectionNode(_: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        dataSource
            .numberOfItems(in: section)
    }
}

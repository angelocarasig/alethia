//
//  CollectionGrid.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import SwiftUI
import UIKit

struct CollectionViewGrid<Data, Cell>: UIViewRepresentable where Data: RandomAccessCollection, Data.Element: Identifiable, Cell: View {
    // Data
    var data: Data
    var content: (Data.Element) -> Cell
    
    // Layout
    var columns: Int = 3
    var spacing: CGFloat = Constants.Spacing.minimal
    var contentInsets: NSDirectionalEdgeInsets = .zero
    
    // UI
    var showsScrollIndicator: Bool = true
    
    // Callbacks
    var onReachedBottom: (() -> Void)?
    var onItemTapped: ((Data.Element) -> Void)?
    
    // For recycling and identifier management
    private let cellIdentifier = "Cell"
    
    // UIViewRepresentable implementation
    func makeUIView(context: Context) -> UICollectionView {
        // Create layout
        let layout = createGridLayout()
        
        // Create collection view
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = showsScrollIndicator
        
        // Register cell
        collectionView.register(HostingCell<Cell>.self, forCellWithReuseIdentifier: cellIdentifier)
        
        // Set up delegate and data source
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        
        return collectionView
    }
    
    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        // Update coordinator
        context.coordinator.parent = self
        
        collectionView.showsVerticalScrollIndicator = showsScrollIndicator
        
        // Update data
        collectionView.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Helper method to create a grid layout
    private func createGridLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0/CGFloat(columns)),
            heightDimension: .estimated(200)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing/2,
            leading: spacing/2,
            bottom: spacing/2,
            trailing: spacing/2
        )
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = contentInsets
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    // Coordinator class
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        var parent: CollectionViewGrid
        
        init(_ parent: CollectionViewGrid) {
            self.parent = parent
        }
        
        // DataSource
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return parent.data.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: parent.cellIdentifier, for: indexPath) as! HostingCell<Cell>
            
            let item = parent.data[parent.data.index(parent.data.startIndex, offsetBy: indexPath.item)]
            cell.setup(rootView: parent.content(item))
            
            return cell
        }
        
        // Delegate
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let item = parent.data[parent.data.index(parent.data.startIndex, offsetBy: indexPath.item)]
            parent.onItemTapped?(item)
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // Check if reached bottom
            let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
            if bottomEdge >= (scrollView.contentSize.height - 100) && parent.onReachedBottom != nil {
                parent.onReachedBottom?()
            }
        }
    }
    
    // Hosting cell to wrap SwiftUI content
    class HostingCell<Content: View>: UICollectionViewCell {
        private var hostingController: UIHostingController<Content>?
        
        override func prepareForReuse() {
            super.prepareForReuse()
            hostingController?.view.removeFromSuperview()
            hostingController = nil
        }
        
        func setup(rootView: Content) {
            if hostingController == nil {
                hostingController = UIHostingController(rootView: rootView)
                hostingController!.view.backgroundColor = .clear
                
                contentView.addSubview(hostingController!.view)
                hostingController!.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController!.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    hostingController!.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                    hostingController!.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    hostingController!.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
                ])
            } else {
                hostingController?.rootView = rootView
            }
        }
    }
}

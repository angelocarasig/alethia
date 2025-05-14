//
//  VerticalReader+DataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/5/2025.
//

import UIKit

extension VerticalReader: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as? PageCell,
              indexPath.item < pages.count else {
            return UICollectionViewCell()
        }
        
        let page = pages[indexPath.item]
        cell.configure(with: page, orientation: orientation)
        visiblePages[indexPath.item] = page
        
        return cell
    }
}

extension VerticalReader: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Prefetch images for upcoming pages
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for indexPath in indexPaths {
                guard let strongSelf = self, indexPath.item < strongSelf.pages.count else { continue }
                
                let page = strongSelf.pages[indexPath.item]
                if let url = URL(string: page.url) {
                    // Start with dimension calculation for layout
                    strongSelf.preloadImage(for: page.url)
                    
                    // Then prefetch the actual image content
                    ImagePrefetcher(urls: [url], options: [.backgroundDecode]).start()
                }
            }
        }
    }
}

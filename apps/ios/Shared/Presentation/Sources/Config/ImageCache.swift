//
//  ImageCache.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Kingfisher
import Foundation

/// Configures image caching for the application
public enum ImageCacheConfiguration {
    
    // MARK: - Cache Names
    
    public enum CacheName: String {
        case covers = "manga_covers"
        case pages = "chapter_pages"
    }
    
    // MARK: - Configuration
    
    /// Call this once at app startup to configure Kingfisher caches
    public static func configure() {
        // configure covers cache
        let coversCache = ImageCache(name: CacheName.covers.rawValue)
        configureCache(coversCache, diskCacheSize: 10 * 1024 * 1024 * 1024) // 10GB for covers
        
        // configure pages cache
        let pagesCache = ImageCache(name: CacheName.pages.rawValue)
        configureCache(pagesCache, diskCacheSize: 15 * 1024 * 1024 * 1024) // 15GB for pages
        
        // configure default cache
        configureCache(ImageCache.default, diskCacheSize: 5 * 1024 * 1024 * 1024) // 5GB default
    }
    
    private static func configureCache(_ cache: ImageCache, diskCacheSize: UInt) {
        // disk storage - long term
        cache.diskStorage.config.expiration = .days(365 * 5) // 5 years
        cache.diskStorage.config.sizeLimit = diskCacheSize
        
        // memory storage - short term
        cache.memoryStorage.config.expiration = .seconds(3600) // 1 hour
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100MB
        cache.memoryStorage.config.countLimit = 100 // max 100 images
    }
}

// MARK: - KFImage Extensions

extension KFImage {
    /// Use the covers cache for manga cover images
    func coverCache() -> Self {
        let cache = ImageCache(name: ImageCacheConfiguration.CacheName.covers.rawValue)
        return self.targetCache(cache)
            .diskCacheExpiration(.days(365 * 5))
    }
    
    /// Use the pages cache for chapter page images
    func pageCache() -> Self {
        let cache = ImageCache(name: ImageCacheConfiguration.CacheName.pages.rawValue)
        return self.targetCache(cache)
            .diskCacheExpiration(.days(365))
    }
}

//
//  ImageCache.swift
//  Presentation
//
//  Created by Angelo Carasig on 10/10/2025.
//

import Kingfisher
import Foundation

/// Manages image caching configuration for the application
public final class ImageCacheConfiguration: Sendable {
    
    // MARK: - Singleton
    
    public static let shared = ImageCacheConfiguration()
    
    // MARK: - Config Constants
    
    private enum CacheSettings {
        static let diskCacheExpiration: StorageExpiration = .days(365 * 5) // 5 years
        static let memoryCacheExpiration: StorageExpiration = .seconds(3600) // 1 hour
        static let diskCacheSizeLimit: UInt = 25 * 1024 * 1024 * 1024 // 25GB
    }
    
    public enum CacheNamespace: Sendable {
        public static let covers = "manga_covers"
        public static let pages = "chapter_pages"
    }
    
    // MARK: - Cache Instances
    
    public let coversCache: ImageCache
    public let pagesCache: ImageCache
    
    // MARK: - Initialization
    
    private init() {
        // covers cache configuration
        self.coversCache = ImageCache(name: CacheNamespace.covers)
        
        // pages cache configuration
        self.pagesCache = ImageCache(name: CacheNamespace.pages)
        
        // configure all caches
        Self.configureCache(coversCache)
        Self.configureCache(pagesCache)
    }
    
    // MARK: - Public Methods
    
    /// Configures Kingfisher's default cache with application-wide settings
    public func configure() {
        Self.configureCache(ImageCache.default)
    }
    
    /// Clears all image caches
    public func clearAllCaches() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    ImageCache.default.clearCache {
                        continuation.resume()
                    }
                }
            }
            
            group.addTask { [coversCache] in
                await withCheckedContinuation { continuation in
                    coversCache.clearCache {
                        continuation.resume()
                    }
                }
            }
            
            group.addTask { [pagesCache] in
                await withCheckedContinuation { continuation in
                    pagesCache.clearCache {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Clears expired images from all caches
    public func cleanExpiredCache() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    ImageCache.default.cleanExpiredDiskCache {
                        continuation.resume()
                    }
                }
            }
            
            group.addTask { [coversCache] in
                await withCheckedContinuation { continuation in
                    coversCache.cleanExpiredDiskCache {
                        continuation.resume()
                    }
                }
            }
            
            group.addTask { [pagesCache] in
                await withCheckedContinuation { continuation in
                    pagesCache.cleanExpiredDiskCache {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Calculates total disk storage size across all caches
    public func calculateTotalCacheSize() async throws -> UInt {
        try await withThrowingTaskGroup(of: UInt.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    ImageCache.default.calculateDiskStorageSize { result in
                        continuation.resume(with: result)
                    }
                }
            }
            
            group.addTask { [coversCache] in
                try await withCheckedThrowingContinuation { continuation in
                    coversCache.calculateDiskStorageSize { result in
                        continuation.resume(with: result)
                    }
                }
            }
            
            group.addTask { [pagesCache] in
                try await withCheckedThrowingContinuation { continuation in
                    pagesCache.calculateDiskStorageSize { result in
                        continuation.resume(with: result)
                    }
                }
            }
            
            var totalSize: UInt = 0
            for try await size in group {
                totalSize += size
            }
            return totalSize
        }
    }
    
    /// Returns formatted cache size string (e.g., "1.5 GB")
    public func formattedCacheSize() async -> String {
        do {
            let size = try await calculateTotalCacheSize()
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
    
    // MARK: - Private Methods
    
    private static func configureCache(_ cache: ImageCache) {
        // disk storage configuration
        cache.diskStorage.config.expiration = CacheSettings.diskCacheExpiration
        cache.diskStorage.config.sizeLimit = CacheSettings.diskCacheSizeLimit
        
        // memory storage configuration
        cache.memoryStorage.config.expiration = CacheSettings.memoryCacheExpiration
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024 // 100MB memory limit
        cache.memoryStorage.config.countLimit = 100 // max 100 images in memory
    }
}

// MARK: - Convenience Extensions

public extension KFImage {
    /// Configures the image to use the covers cache with long-term storage
    func useCoverCache() -> Self {
        self.targetCache(ImageCacheConfiguration.shared.coversCache)
    }
    
    /// Configures the image to use the pages cache
    func usePageCache() -> Self {
        self.targetCache(ImageCacheConfiguration.shared.pagesCache)
    }
}

// MARK: - KingfisherOptionsInfo Extension

public extension Array where Element == KingfisherOptionsInfoItem {
    /// Options for manga cover images with long-term caching
    static var coverOptions: [KingfisherOptionsInfoItem] {
        [
            .targetCache(ImageCacheConfiguration.shared.coversCache),
            .diskCacheExpiration(.days(365 * 5))
        ]
    }
    
    /// Options for chapter page images
    static var pageOptions: [KingfisherOptionsInfoItem] {
        [
            .targetCache(ImageCacheConfiguration.shared.pagesCache),
            .diskCacheExpiration(.days(365))
        ]
    }
}

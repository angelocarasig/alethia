//
//  KingfisherProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import Kingfisher

final class KingfisherProvider {
    static let shared = KingfisherProvider()
    
    private init() {
        // Configs
        let cache = KingfisherManager.shared.cache
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024  // 300 MB
        cache.diskStorage.config.sizeLimit = 1000 * 1024 * 1024        // 1 GB
        
        // Add download timeout
        KingfisherManager.shared.downloader.sessionConfiguration.timeoutIntervalForRequest = 30
    }
}

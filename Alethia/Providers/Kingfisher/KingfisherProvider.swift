//
//  KingfisherProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 22/5/2025.
//

import Foundation
import Kingfisher

final class KingfisherProvider {
    static let shared = KingfisherProvider()
    
    private init() {
        let cache = KingfisherManager.shared.cache
        // Max 500MB in memory cache
        cache.memoryStorage.config.totalCostLimit = 500 * 1024 * 1024
        cache.memoryStorage.config.countLimit = 100
    }
    
    static let prefetchOptions: KingfisherOptionsInfo = [
        .backgroundDecode,
        .downloadPriority(0.3),
        .retryStrategy(DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(2)))
    ]
}

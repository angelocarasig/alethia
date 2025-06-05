//
//  EntryQueueState.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation

/// Used to determine what operations are being applied for a given entry based on mangaId
struct EntryQueueState: OptionSet {
    let rawValue: Int
    
    static let downloading = EntryQueueState(rawValue: 1 << 0)
    static let updatingMetadata = EntryQueueState(rawValue: 1 << 1)
    
    static let idle: EntryQueueState = []
    static let busy: EntryQueueState = [.downloading, .updatingMetadata]
    
    var isEmpty: Bool { rawValue == 0 }
    var isBusy: Bool { !isEmpty }
    var isDownloading: Bool { contains(.downloading) }
    var isUpdatingMetadata: Bool { contains(.updatingMetadata) }
}

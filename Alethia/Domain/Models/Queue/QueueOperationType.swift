//
//  QueueOperationType.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Foundation

/// The type of operation a queue operation object contains
enum QueueOperationType {
    case chapterDownload(Chapter)
    case metadataRefresh(Entry)
}

//
//  ReaderError.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// errors that can occur during reader operations
public enum ReaderError: Error {
    case invalidChapterId
    case chapterNotFound
    case invalidState
}

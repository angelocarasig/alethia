//
//  ReaderError.swift
//  Reader
//
//  Created by Angelo Carasig on 22/10/2025.
//

import Foundation

/// errors that can occur during reader operations
public enum ReaderError: Error, LocalizedError {
    case invalidChapterId
    case chapterNotFound
    case invalidState
    case initialChapterFailed(Error)
    case subsequentChapterFailed(chapterId: ChapterID, Error)
    case emptyPages(chapterId: ChapterID)
    
    public var errorDescription: String? {
        switch self {
        case .invalidChapterId:
            return "Invalid Chapter"
        case .chapterNotFound:
            return "Chapter Not Found"
        case .invalidState:
            return "Reader Error"
        case .initialChapterFailed:
            return "Failed to Load Chapter"
        case .subsequentChapterFailed:
            return "Failed to Load Chapter"
        case .emptyPages:
            return "Chapter is Empty"
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidChapterId:
            return "The chapter ID is invalid."
        case .chapterNotFound:
            return "The requested chapter could not be found."
        case .invalidState:
            return "The reader is in an invalid state."
        case .initialChapterFailed(let error):
            return "Could not load the chapter: \(error.localizedDescription)"
        case .subsequentChapterFailed(_, let error):
            return "Could not load the next chapter: \(error.localizedDescription)"
        case .emptyPages:
            return "This chapter has no pages to display."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .initialChapterFailed, .subsequentChapterFailed:
            return "Check your internet connection and try again."
        case .emptyPages:
            return "Try navigating to a different chapter."
        case .invalidChapterId, .chapterNotFound, .invalidState:
            return "Please restart the reader."
        }
    }
    
    public var isInitialError: Bool {
        if case .initialChapterFailed = self {
            return true
        }
        return false
    }
}

//
//  VerticalReader+Delegate.swift
//  Alethia
//
//  Created by Angelo Carasig on 14/5/2025.
//

protocol VerticalReaderDelegate: AnyObject {
    func didScrollToPage(_ page: Page)
    func didFinishChapter(_ chapter: Chapter)
    func didChangeChapter(from previousChapter: Chapter, to newChapter: Chapter)
    func didStartScrolling()
}
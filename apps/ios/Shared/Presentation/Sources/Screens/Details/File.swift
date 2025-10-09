////
////  File.swift
////  Presentation
////
////  Created by Angelo Carasig on 9/10/2025.
////
//
//import Foundation
//import Domain
//
//extension Manga {
//    public static var previewManga: Manga {
//        let synopsis = try! AttributedString(
//            markdown: "After his sister is devoured by a dragon and losing all their supplies in a failed dungeon raid, Laios and his party are determined to save his sister before she gets digested. Completely broke and having to resort to eating monsters as food, they meet a dwarf who will introduce them to the world of Dungeon Meshi - delicious cuisine made from ingredients such as the monsters of the dungeon.",
//            options: AttributedString.MarkdownParsingOptions(
//                interpretedSyntax: .inlineOnlyPreservingWhitespace
//            )
//        )
//        
//        let covers = [
//            URL(string: "https://mangadex.org/covers/77bee52c-d2d6-44ad-a33a-1734c1fe696a/cover.jpg")!
//        ]
//        
//        let origins = [
//            Origin(
//                id: 1,
//                slug: "77bee52c-d2d6-44ad-a33a-1734c1fe696a",
//                url: URL(string: "https://mangadex.org/title/77bee52c-d2d6-44ad-a33a-1734c1fe696a")!,
//                priority: 0,
//                classification: .Safe,
//                status: .Completed
//            )
//        ]
//        
//        let chapterRange = Array(1...97)
//        let chapters = chapterRange.map { num in
//            Chapter(
//                id: Int64(num),
//                slug: "chapter-\(num)",
//                title: num % 5 == 0 ? "Special Chapter \(num)" : "",
//                number: Double(num),
//                date: Date().addingTimeInterval(-Double(num) * 86400),
//                scanlator: "Scanlator Group",
//                language: LanguageCode("en"),
//                url: "https://example.com/chapter/\(num)",
//                icon: URL(string: "https://mangadex.org/img/mangadex-logo.svg"),
//                progress: num <= 45 ? 1.0 : (num == 46 ? 0.6 : 0.0)
//            )
//        }
//        
//        return Manga(
//            id: 1,
//            title: "Dungeon Meshi",
//            authors: ["Kui Ryouko"],
//            synopsis: synopsis,
//            alternativeTitles: ["ダンジョン飯", "Delicious in Dungeon"],
//            tags: ["Adventure", "Comedy", "Fantasy", "Cooking", "Seinen"],
//            covers: covers,
//            origins: origins,
//            chapters: chapters,
//            inLibrary: true,
//            addedAt: Date().addingTimeInterval(-86400 * 60),
//            updatedAt: Date().addingTimeInterval(-86400 * 3),
//            lastFetchedAt: Date().addingTimeInterval(-86400),
//            lastReadAt: Date().addingTimeInterval(-86400 * 2),
//            orientation: .rightToLeft,
//            showAllChapters: true,
//            showHalfChapters: false
//        )
//    }
//}

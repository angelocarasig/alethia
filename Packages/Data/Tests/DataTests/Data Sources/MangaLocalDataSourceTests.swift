//
//  MangaLocalDataSourceTests.swift
//  DataTests
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import Testing
import GRDB
import Domain
import Combine
@testable import Data

@Suite("MangaLocalDataSource Tests")
struct MangaLocalDataSourceTests {
    var database: DatabaseWriter
    var dataSource: MangaLocalDataSource
    
    init() throws {
        self.database = try makeTestDatabase()
        self.dataSource = MangaLocalDataSource(database: database)
    }
    
    @Test("test_getMangaDetails_withValidMangaId_returnsSingleMatch")
    func testFetchByMangaId() async throws {
        // arrange
        let manga = Domain.Models.Persistence.Manga.makeTest()
        try await database.write { db in
            try manga.insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Different Title",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        #expect(details.count == 1)
        #expect(details.first?.manga.id == 1)
        #expect(details.first?.manga.title == "Test Manga")
    }
    
    @Test("test_getMangaDetails_withInvalidMangaId_fallsBackToTitleSearch")
    func testFallbackToTitleSearch() async throws {
        // arrange
        let manga = Domain.Models.Persistence.Manga.makeTest(
            id: 999,
            title: "Naruto"
        )
        try await database.write { db in
            try manga.insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1, // wrong id
            sourceId: nil,
            title: "Naruto", // correct title
            slug: "naruto",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert - found by title despite wrong id
        #expect(details.count == 1)
        #expect(details.first?.manga.id == 999)
        #expect(details.first?.manga.title == "Naruto")
    }
    
    @Test("test_getMangaDetails_withMatchingTitle_returnsSingleMatch")
    func testFetchByTitle() async throws {
        // arrange
        let manga = Domain.Models.Persistence.Manga.makeTest(title: "One Piece")
        try await database.write { db in
            try manga.insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: nil,
            sourceId: nil,
            title: "One Piece",
            slug: "one-piece",
            cover: "",
            inLibrary: false
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        #expect(details.count == 1)
        #expect(details.first?.manga.title == "One Piece")
    }
    
    @Test("test_getMangaDetails_withDuplicateTitles_returnsAllMatches")
    func testFetchDuplicateTitles() async throws {
        // arrange
        let manga1 = Domain.Models.Persistence.Manga.makeTest(
            id: 1,
            title: "Bleach"
        )
        let manga2 = Domain.Models.Persistence.Manga.makeTest(
            id: 2,
            title: "Bleach"
        )
        let manga3 = Domain.Models.Persistence.Manga.makeTest(
            id: 3,
            title: "Bleach: Alternative"
        )
        
        try await database.write { db in
            try manga1.insert(db)
            try manga2.insert(db)
            try manga3.insert(db)
            
            // add alternative title to manga3
            try Domain.Models.Persistence.Title(
                mangaId: 3,
                title: "Bleach"
            ).insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: nil,
            sourceId: nil,
            title: "Bleach",
            slug: "bleach",
            cover: "",
            inLibrary: false
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert - should find all 3 matches
        #expect(details.count == 3)
        
        // assert - verify all ids are present
        let foundIds = Set(details.compactMap { $0.manga.id })
        #expect(foundIds == Set([1, 2, 3]))
    }
    
    @Test("test_getMangaDetails_withNoMatches_returnsEmptyArray")
    func testNoMatches() async throws {
        // arrange
        let entry = Domain.Models.Virtual.Entry(
            mangaId: nil,
            sourceId: nil,
            title: "Non-existent Manga",
            slug: "test",
            cover: "",
            inLibrary: false
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        #expect(details.isEmpty)
    }
    
    @Test("test_getMangaDetails_withAllRelations_returnsCompleteDetails")
    func testFetchWithRelations() async throws {
        // arrange
        try await database.write { db in
            // manga
            let manga = Domain.Models.Persistence.Manga.makeTest()
            try manga.insert(db)
            
            // titles
            try Domain.Models.Persistence.Title(
                mangaId: 1,
                title: "Alternative Title"
            ).insert(db)
            
            // author
            let author = Domain.Models.Persistence.Author(name: "Test Author")
            try author.insert(db)
            try Domain.Models.Persistence.MangaAuthor(
                mangaId: 1,
                authorId: 1
            ).insert(db)
            
            // tag
            let tag = Domain.Models.Persistence.Tag(name: "Action")
            try tag.insert(db)
            try Domain.Models.Persistence.MangaTag(
                mangaId: 1,
                tagId: 1
            ).insert(db)
            
            // cover
            try Domain.Models.Persistence.Cover(
                mangaId: 1,
                active: true,
                url: "https://example.com/cover.jpg",
                path: "/covers/1.jpg"
            ).insert(db)
            
            // collection
            let collection = try Domain.Models.Persistence.Collection(
                name: "Favorites",
                color: "#FF0000",
                icon: "star.fill"
            )
            try collection.insert(db)
            try Domain.Models.Persistence.MangaCollection(
                mangaId: 1,
                collectionId: 1
            ).insert(db)
            
            // source/origin setup
            let host = try Domain.Models.Persistence.Host(
                name: "test host",
                author: "test",
                repository: "https://test.com",
                baseUrl: "https://api.test.com"
            )
            try host.insert(db)
            
            let source = Domain.Models.Persistence.Source(
                hostId: 1,
                name: "Test Source",
                icon: "/icon.png",
                path: "test",
                website: "https://test.com",
                description: "Test"
            )
            try source.insert(db)
            
            let origin = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga",
                url: "https://test.com/test-manga",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0
            )
            try origin.insert(db)
            
            // scanlator
            let scanlator = Domain.Models.Persistence.Scanlator(name: "Test Scans")
            try scanlator.insert(db)
            
            // channel
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 1,
                priority: 0
            ).insert(db)
            
            // chapter
            try Domain.Models.Persistence.Chapter.makeTest().insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Test",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert - single result
        #expect(details.count == 1)
        let detail = try #require(details.first)
        
        // assert - all relations loaded
        #expect(detail.titles.count == 1)
        #expect(detail.authors.count == 1)
        #expect(detail.covers.count == 1)
        #expect(detail.tags.count == 1)
        #expect(detail.collections.count == 1)
        #expect(detail.sources.count == 1)
        #expect(detail.chapters.count == 1)
        
        // assert - nested data correct
        #expect(detail.sources.first?.scanlators.count == 1)
        #expect(detail.chapters.first?.scanlator.name == "Test Scans")
    }
    
    @Test("test_getMangaDetails_withShowAllChaptersFalse_returnsOnlyBestChapters")
    func testChapterPriorityWithShowAllChaptersFalse() async throws {
        // arrange
        try await database.write { db in
            // manga with showAllChapters = false (default)
            let manga = Domain.Models.Persistence.Manga.makeTest()
            try manga.insert(db)
            
            // setup sources
            let host = try Domain.Models.Persistence.Host(
                name: "test host",
                author: "test",
                repository: "https://test.com",
                baseUrl: "https://api.test.com"
            )
            try host.insert(db)
            
            let source = Domain.Models.Persistence.Source(
                hostId: 1,
                name: "Test Source",
                icon: "/icon.png",
                path: "test",
                website: "https://test.com",
                description: "Test"
            )
            try source.insert(db)
            
            // create two origins with different priorities
            let origin1 = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga-1",
                url: "https://test.com/test-manga-1",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0 // higher priority
            )
            try origin1.insert(db)
            
            let origin2 = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga-2",
                url: "https://test.com/test-manga-2",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 1 // lower priority
            )
            try origin2.insert(db)
            
            // scanlators
            let scanlator1 = Domain.Models.Persistence.Scanlator(name: "Priority Scans")
            try scanlator1.insert(db)
            
            let scanlator2 = Domain.Models.Persistence.Scanlator(name: "Regular Scans")
            try scanlator2.insert(db)
            
            // channels
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 1,
                priority: 0
            ).insert(db)
            
            try Domain.Models.Persistence.Channel(
                originId: 2,
                scanlatorId: 2,
                priority: 0
            ).insert(db)
            
            // duplicate chapters - same number from different origins
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 10 - Priority",
                slug: "chapter-10-priority",
                number: 10.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
            
            try Domain.Models.Persistence.Chapter(
                originId: 2,
                scanlatorId: 2,
                title: "Chapter 10 - Regular",
                slug: "chapter-10-regular",
                number: 10.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Test",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        let detail = try #require(details.first)
        #expect(detail.chapters.count == 1) // only best chapter
        #expect(detail.chapters.first?.chapter.title == "Chapter 10 - Priority")
        #expect(detail.chapters.first?.scanlator.name == "Priority Scans")
    }
    
    @Test("test_getMangaDetails_withShowAllChaptersTrue_returnsAllChapters")
    func testChapterPriorityWithShowAllChaptersTrue() async throws {
        // arrange
        try await database.write { db in
            // manga with showAllChapters = true
            var manga = Domain.Models.Persistence.Manga.makeTest()
            manga.showAllChapters = true
            try manga.insert(db)
            
            // setup sources (reusing setup from previous test)
            let host = try Domain.Models.Persistence.Host(
                name: "test host",
                author: "test",
                repository: "https://test.com",
                baseUrl: "https://api.test.com"
            )
            try host.insert(db)
            
            let source = Domain.Models.Persistence.Source(
                hostId: 1,
                name: "Test Source",
                icon: "/icon.png",
                path: "test",
                website: "https://test.com",
                description: "Test"
            )
            try source.insert(db)
            
            // create two origins
            let origin1 = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga-1",
                url: "https://test.com/test-manga-1",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0
            )
            try origin1.insert(db)
            
            let origin2 = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga-2",
                url: "https://test.com/test-manga-2",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 1
            )
            try origin2.insert(db)
            
            // scanlators
            let scanlator1 = Domain.Models.Persistence.Scanlator(name: "Priority Scans")
            try scanlator1.insert(db)
            
            let scanlator2 = Domain.Models.Persistence.Scanlator(name: "Regular Scans")
            try scanlator2.insert(db)
            
            // channels
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 1,
                priority: 0
            ).insert(db)
            
            try Domain.Models.Persistence.Channel(
                originId: 2,
                scanlatorId: 2,
                priority: 0
            ).insert(db)
            
            // duplicate chapters - same number
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 10 - Priority",
                slug: "chapter-10-priority",
                number: 10.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
            
            try Domain.Models.Persistence.Chapter(
                originId: 2,
                scanlatorId: 2,
                title: "Chapter 10 - Regular",
                slug: "chapter-10-regular",
                number: 10.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Test",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        let detail = try #require(details.first)
        #expect(detail.chapters.count == 2) // all chapters shown
        
        // assert - both chapters present
        let chapterTitles = Set(detail.chapters.map { $0.chapter.title })
        #expect(chapterTitles == Set(["Chapter 10 - Priority", "Chapter 10 - Regular"]))
    }
    
    @Test("test_getMangaDetails_withShowHalfChaptersFalse_filtersDecimalChapters")
    func testChapterFilteringWithShowHalfChaptersFalse() async throws {
        // arrange
        try await database.write { db in
            // manga with showHalfChapters = false
            var manga = Domain.Models.Persistence.Manga.makeTest()
            manga.showHalfChapters = false
            try manga.insert(db)
            
            // setup minimal requirements
            let host = try Domain.Models.Persistence.Host(
                name: "test host",
                author: "test",
                repository: "https://test.com",
                baseUrl: "https://api.test.com"
            )
            try host.insert(db)
            
            let source = Domain.Models.Persistence.Source(
                hostId: 1,
                name: "Test Source",
                icon: "/icon.png",
                path: "test",
                website: "https://test.com",
                description: "Test"
            )
            try source.insert(db)
            
            let origin = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga",
                url: "https://test.com/test-manga",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0
            )
            try origin.insert(db)
            
            let scanlator = Domain.Models.Persistence.Scanlator(name: "Test Scans")
            try scanlator.insert(db)
            
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 1,
                priority: 0
            ).insert(db)
            
            // mix of integer and decimal chapters
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 10",
                slug: "chapter-10",
                number: 10.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
            
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 10.5",
                slug: "chapter-10-5",
                number: 10.5,
                date: Date(),
                progress: 0.0
            ).insert(db)
            
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 11",
                slug: "chapter-11",
                number: 11.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Test",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        let detail = try #require(details.first)
        #expect(detail.chapters.count == 2) // only integer chapters
        
        // assert - verify only integer chapters present
        let chapterNumbers = Set(detail.chapters.map { $0.chapter.number })
        #expect(chapterNumbers == Set([10.0, 11.0]))
    }
    
    @Test("test_getMangaDetails_withChannelPriorities_respectsScanlatorOrder")
    func testChannelPriorityOrdering() async throws {
        // arrange
        try await database.write { db in
            let manga = Domain.Models.Persistence.Manga.makeTest()
            try manga.insert(db)
            
            // setup source
            let host = try Domain.Models.Persistence.Host(
                name: "test host",
                author: "test",
                repository: "https://test.com",
                baseUrl: "https://api.test.com"
            )
            try host.insert(db)
            
            let source = Domain.Models.Persistence.Source(
                hostId: 1,
                name: "Test Source",
                icon: "/icon.png",
                path: "test",
                website: "https://test.com",
                description: "Test"
            )
            try source.insert(db)
            
            let origin = Domain.Models.Persistence.Origin(
                sourceId: 1,
                mangaId: 1,
                slug: "test-manga",
                url: "https://test.com/test-manga",
                referer: "https://test.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0
            )
            try origin.insert(db)
            
            // multiple scanlators with different priorities
            let scanlator1 = Domain.Models.Persistence.Scanlator(name: "Low Priority Scans")
            try scanlator1.insert(db)
            
            let scanlator2 = Domain.Models.Persistence.Scanlator(name: "High Priority Scans")
            try scanlator2.insert(db)
            
            // channels with different priorities (lower number = higher priority)
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 1,
                priority: 1 // lower priority
            ).insert(db)
            
            try Domain.Models.Persistence.Channel(
                originId: 1,
                scanlatorId: 2,
                priority: 0 // higher priority
            ).insert(db)
            
            // same chapter from different scanlators
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 1,
                title: "Chapter 5 - Low Priority",
                slug: "chapter-5-low",
                number: 5.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
            
            try Domain.Models.Persistence.Chapter(
                originId: 1,
                scanlatorId: 2,
                title: "Chapter 5 - High Priority",
                slug: "chapter-5-high",
                number: 5.0,
                date: Date(),
                progress: 0.0
            ).insert(db)
        }
        
        let entry = Domain.Models.Virtual.Entry(
            mangaId: 1,
            sourceId: nil,
            title: "Test",
            slug: "test",
            cover: "",
            inLibrary: true
        )
        
        // act
        let details = try await dataSource.getMangaDetails(entry: entry)
            .async()
        
        // assert
        let detail = try #require(details.first)
        #expect(detail.chapters.count == 1) // only best chapter
        #expect(detail.chapters.first?.chapter.title == "Chapter 5 - High Priority")
        #expect(detail.chapters.first?.scanlator.name == "High Priority Scans")
    }
}

// helper to convert publisher to async
private extension Publisher {
    func async() async throws -> Output {
        try await self
            .first()
            .values
            .first(where: { _ in true })!
    }
}

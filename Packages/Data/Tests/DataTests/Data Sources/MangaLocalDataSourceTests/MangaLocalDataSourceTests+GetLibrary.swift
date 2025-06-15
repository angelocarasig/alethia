//
//  MangaLocalDataSourceTests+GetLibrary.swift
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

private extension Publisher {
    func async() async throws -> Output {
        try await self
            .first()
            .values
            .first(where: { _ in true })!
    }
}

extension MangaLocalDataSourceTests {
    @Suite("GetLibrary Tests")
    struct GetLibraryTests {
        var database: DatabaseWriter
        var dataSource: MangaLocalDataSource
        
        init() throws {
            self.database = try makeTestDatabase()
            self.dataSource = MangaLocalDataSource(database: database)
        }
        
        // MARK: - Basic Library Tests
        
        @Test("test_getLibrary_withNoFilters_returnsAllInLibraryManga")
        func testBasicLibraryFetch() async throws {
            // arrange
            try await database.write { db in
                // create manga in library
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "One Piece")
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Naruto")
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // create manga not in library
                var manga3 = Domain.Models.Persistence.Manga.makeTest(id: 3, title: "Bleach")
                manga3.inLibrary = false
                try manga3.insert(db)
            }
            
            let filters = Domain.Models.Presentation.LibraryFilters()
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 2)
            #expect(entries.allSatisfy { $0.inLibrary })
            #expect(Set(entries.map { $0.title }) == Set(["One Piece", "Naruto"]))
        }
        
        @Test("test_getLibrary_withEmptyLibrary_returnsEmptyArray")
        func testEmptyLibrary() async throws {
            // arrange - no manga in library
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest()
                manga.inLibrary = false
                try manga.insert(db)
            }
            
            let filters = Domain.Models.Presentation.LibraryFilters()
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.isEmpty)
        }
        
        // MARK: - Collection Filter Tests
        
        @Test("test_getLibrary_withCollectionFilter_returnsOnlyMangaInCollection")
        func testCollectionFilter() async throws {
            // arrange
            try await database.write { db in
                // create collections
                let collection1 = try Domain.Models.Persistence.Collection(
                    name: "Favorites",
                    color: "#FF0000",
                    icon: "star.fill"
                )
                try collection1.insert(db)
                
                let collection2 = try Domain.Models.Persistence.Collection(
                    name: "Reading",
                    color: "#00FF00",
                    icon: "book.fill"
                )
                try collection2.insert(db)
                
                // create manga
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "One Piece")
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Naruto")
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // add manga to collections
                try Domain.Models.Persistence.MangaCollection(mangaId: 1, collectionId: 1).insert(db)
                try Domain.Models.Persistence.MangaCollection(mangaId: 2, collectionId: 2).insert(db)
            }
            
            let filters = Domain.Models.Presentation.LibraryFilters()
            
            // act - filter by collection 1
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: 1)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "One Piece")
        }
        
        @Test("test_getLibrary_withInvalidCollection_throwsError")
        func testInvalidCollectionFilter() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest()
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            let filters = Domain.Models.Presentation.LibraryFilters()
            
            // act & assert
            await #expect(throws: Domain.Models.Persistence.CollectionError.self) {
                _ = try await dataSource.getLibrary(filters: filters, collectionId: 999)
                    .async()
            }
        }
        
        // MARK: - Search Filter Tests
        
        @Test("test_getLibrary_withSearchText_returnsMatchingManga")
        func testSearchFilter() async throws {
            // arrange
            try await database.write { db in
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "One Piece")
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "One Punch Man")
                manga2.inLibrary = true
                try manga2.insert(db)
                
                var manga3 = Domain.Models.Persistence.Manga.makeTest(id: 3, title: "Naruto")
                manga3.inLibrary = true
                try manga3.insert(db)
                
                // add alternative title
                try Domain.Models.Persistence.Title(
                    mangaId: 3,
                    title: "Naruto Shippuden"
                ).insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "One"
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 2)
            #expect(Set(entries.map { $0.title }) == Set(["One Piece", "One Punch Man"]))
        }
        
        @Test("test_getLibrary_withSearchText_searchesAlternativeTitles")
        func testSearchAlternativeTitles() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Attack on Titan")
                manga.inLibrary = true
                try manga.insert(db)
                
                // add alternative titles
                try Domain.Models.Persistence.Title(
                    mangaId: 1,
                    title: "Shingeki no Kyojin"
                ).insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "Shingeki"
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Attack on Titan")
        }
        
        @Test("test_getLibrary_withSearchText_handlesSpecialCharacters")
        func testSearchSpecialCharacters() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Re:Zero")
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "Re:"
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Re:Zero")
        }
        
        // MARK: - Date Filter Tests
        
        @Test("test_getLibrary_withAddedAtFilter_returnsFilteredManga")
        func testAddedAtFilter() async throws {
            // arrange
            let oldDate = Date(timeIntervalSinceNow: -86400 * 30) // 30 days ago
            let recentDate = Date(timeIntervalSinceNow: -86400) // 1 day ago
            
            try await database.write { db in
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Old Manga")
                manga1.inLibrary = true
                manga1.addedAt = oldDate
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Recent Manga")
                manga2.inLibrary = true
                manga2.addedAt = recentDate
                try manga2.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.addedAt = .after(date: Date(timeIntervalSinceNow: -86400 * 7)) // after 7 days ago
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Recent Manga")
        }
        
        @Test("test_getLibrary_withUpdatedAtFilter_returnsFilteredManga")
        func testUpdatedAtFilter() async throws {
            // arrange
            let oldDate = Date(timeIntervalSinceNow: -86400 * 30)
            let recentDate = Date(timeIntervalSinceNow: -86400)
            
            try await database.write { db in
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Old Update")
                manga1.inLibrary = true
                manga1.updatedAt = oldDate
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Recent Update")
                manga2.inLibrary = true
                manga2.updatedAt = recentDate
                try manga2.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.updatedAt = .before(date: Date(timeIntervalSinceNow: -86400 * 14))
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Old Update")
        }
        
        @Test("test_getLibrary_withBetweenDateFilter_returnsFilteredManga")
        func testBetweenDateFilter() async throws {
            // arrange
            let veryOld = Date(timeIntervalSinceNow: -86400 * 60)
            let inRange = Date(timeIntervalSinceNow: -86400 * 15)
            let tooRecent = Date(timeIntervalSinceNow: -86400 * 2)
            
            try await database.write { db in
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Very Old")
                manga1.inLibrary = true
                manga1.addedAt = veryOld
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "In Range")
                manga2.inLibrary = true
                manga2.addedAt = inRange
                try manga2.insert(db)
                
                var manga3 = Domain.Models.Persistence.Manga.makeTest(id: 3, title: "Too Recent")
                manga3.inLibrary = true
                manga3.addedAt = tooRecent
                try manga3.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.addedAt = .between(
                start: Date(timeIntervalSinceNow: -86400 * 30),
                end: Date(timeIntervalSinceNow: -86400 * 10)
            )
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "In Range")
        }
        
        // MARK: - Metadata Filter Tests
        
        @Test("test_getLibrary_withPublishStatusFilter_returnsFilteredManga")
        func testPublishStatusFilter() async throws {
            // arrange
            try await database.write { db in
                // setup source infrastructure
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
                
                // create manga with different statuses
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Ongoing Series")
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Completed Series")
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // create origins with different statuses
                let origin1 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 1,
                    slug: "ongoing",
                    url: "https://test.com/ongoing",
                    referer: "https://test.com",
                    classification: .Safe,
                    status: .Ongoing,
                    createdAt: Date(),
                    priority: 0
                )
                try origin1.insert(db)
                
                let origin2 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 2,
                    slug: "completed",
                    url: "https://test.com/completed",
                    referer: "https://test.com",
                    classification: .Safe,
                    status: .Completed,
                    createdAt: Date(),
                    priority: 0
                )
                try origin2.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.publishStatus = [.Ongoing]
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Ongoing Series")
        }
        
        @Test("test_getLibrary_withMultiplePublishStatuses_returnsFilteredManga")
        func testMultiplePublishStatusFilter() async throws {
            // arrange
            try await database.write { db in
                // setup source infrastructure
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
                
                // create manga
                for i in 1...3 {
                    var manga = Domain.Models.Persistence.Manga.makeTest(
                        id: Int64(i),
                        title: "Manga \(i)"
                    )
                    manga.inLibrary = true
                    try manga.insert(db)
                }
                
                // create origins with different statuses
                let statuses: [Domain.Models.Enums.PublishStatus] = [.Ongoing, .Completed, .Hiatus]
                for (index, status) in statuses.enumerated() {
                    let origin = Domain.Models.Persistence.Origin(
                        sourceId: 1,
                        mangaId: Int64(index + 1),
                        slug: "manga-\(index + 1)",
                        url: "https://test.com/manga-\(index + 1)",
                        referer: "https://test.com",
                        classification: .Safe,
                        status: status,
                        createdAt: Date(),
                        priority: 0
                    )
                    try origin.insert(db)
                }
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.publishStatus = [.Ongoing, .Completed]
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 2)
            #expect(Set(entries.map { $0.title }) == Set(["Manga 1", "Manga 2"]))
        }
        
        @Test("test_getLibrary_withClassificationFilter_returnsFilteredManga")
        func testClassificationFilter() async throws {
            // arrange
            try await database.write { db in
                // setup source infrastructure
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
                
                // create manga
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Safe Content")
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Explicit Content")
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // create origins with different classifications
                let origin1 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 1,
                    slug: "safe",
                    url: "https://test.com/safe",
                    referer: "https://test.com",
                    classification: .Safe,
                    status: .Ongoing,
                    createdAt: Date(),
                    priority: 0
                )
                try origin1.insert(db)
                
                let origin2 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 2,
                    slug: "explicit",
                    url: "https://test.com/explicit",
                    referer: "https://test.com",
                    classification: .Explicit,
                    status: .Ongoing,
                    createdAt: Date(),
                    priority: 0
                )
                try origin2.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.classification = [.Safe]
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Safe Content")
        }
        
        // MARK: - Sorting Tests
        
        @Test("test_getLibrary_withTitleSort_returnsSortedManga")
        func testTitleSort() async throws {
            // arrange
            try await database.write { db in
                let titles = ["Zeta", "Alpha", "Beta"]
                for (index, title) in titles.enumerated() {
                    var manga = Domain.Models.Persistence.Manga.makeTest(
                        id: Int64(index + 1),
                        title: title
                    )
                    manga.inLibrary = true
                    try manga.insert(db)
                }
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.sortType = .title
            filters.sortDirection = .descending // A-Z for titles
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.map { $0.title } == ["Alpha", "Beta", "Zeta"])
        }
        
        @Test("test_getLibrary_withDateAddedSort_returnsSortedManga")
        func testDateAddedSort() async throws {
            // arrange
            let dates = [
                Date(timeIntervalSinceNow: -86400 * 3),
                Date(timeIntervalSinceNow: -86400 * 1),
                Date(timeIntervalSinceNow: -86400 * 2)
            ]
            
            try await database.write { db in
                for (index, date) in dates.enumerated() {
                    var manga = Domain.Models.Persistence.Manga.makeTest(
                        id: Int64(index + 1),
                        title: "Manga \(index + 1)"
                    )
                    manga.inLibrary = true
                    manga.addedAt = date
                    try manga.insert(db)
                }
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.sortType = .added
            filters.sortDirection = .descending // newest first
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.first?.title == "Manga 2") // most recent
            #expect(entries.last?.title == "Manga 1") // oldest
        }
        
        @Test("test_getLibrary_withLastReadSort_returnsSortedManga")
        func testLastReadSort() async throws {
            // arrange
            try await database.write { db in
                // manga with no read date
                var manga1 = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Never Read")
                manga1.inLibrary = true
                manga1.lastReadAt = nil
                try manga1.insert(db)
                
                // manga read recently
                var manga2 = Domain.Models.Persistence.Manga.makeTest(id: 2, title: "Recently Read")
                manga2.inLibrary = true
                manga2.lastReadAt = Date(timeIntervalSinceNow: -3600) // 1 hour ago
                try manga2.insert(db)
                
                // manga read long ago
                var manga3 = Domain.Models.Persistence.Manga.makeTest(id: 3, title: "Old Read")
                manga3.inLibrary = true
                manga3.lastReadAt = Date(timeIntervalSinceNow: -86400 * 7) // 1 week ago
                try manga3.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.sortType = .read
            filters.sortDirection = .descending // most recent first
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.map { $0.title } == ["Recently Read", "Old Read", "Never Read"])
        }
        
        // MARK: - Complex Filter Combination Tests
        
        @Test("test_getLibrary_withMultipleFilters_returnsCorrectlyFilteredManga")
        func testComplexFiltering() async throws {
            // arrange
            try await database.write { db in
                // setup infrastructure
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
                
                // create collection
                let collection = try Domain.Models.Persistence.Collection(
                    name: "Action",
                    color: "#FF0000",
                    icon: "flame.fill"
                )
                try collection.insert(db)
                
                // create multiple manga with various properties
                for i in 1...5 {
                    var manga = Domain.Models.Persistence.Manga.makeTest(
                        id: Int64(i),
                        title: "Action Manga \(i)"
                    )
                    manga.inLibrary = true
                    manga.addedAt = Date(timeIntervalSinceNow: -86400 * Double(i * 5))
                    try manga.insert(db)
                    
                    // add some to collection
                    if i <= 3 {
                        try Domain.Models.Persistence.MangaCollection(
                            mangaId: Int64(i),
                            collectionId: 1
                        ).insert(db)
                    }
                    
                    // create origins with varied statuses
                    let status: Domain.Models.Enums.PublishStatus = i % 2 == 0 ? .Ongoing : .Completed
                    let origin = Domain.Models.Persistence.Origin(
                        sourceId: 1,
                        mangaId: Int64(i),
                        slug: "manga-\(i)",
                        url: "https://test.com/manga-\(i)",
                        referer: "https://test.com",
                        classification: .Safe,
                        status: status,
                        createdAt: Date(),
                        priority: 0
                    )
                    try origin.insert(db)
                }
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "Action"
            filters.publishStatus = [.Ongoing]
            filters.addedAt = .after(date: Date(timeIntervalSinceNow: -86400 * 20))
            filters.sortType = .title
            filters.sortDirection = .ascending // Z-A for titles
            
            // act - with collection filter
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: 1)
                .async()
            
            // assert
            #expect(entries.count == 1) // only manga 2 matches all criteria
            #expect(entries.first?.title == "Action Manga 2")
        }
        
        // MARK: - Priority Filter Tests
        
        @Test("test_getLibrary_withMultipleOrigins_usesHighestPriorityForFilters")
        func testPriorityBasedFiltering() async throws {
            // arrange
            try await database.write { db in
                // setup infrastructure
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
                
                // create manga
                var manga = Domain.Models.Persistence.Manga.makeTest(id: 1, title: "Multi-Origin")
                manga.inLibrary = true
                try manga.insert(db)
                
                // create multiple origins with different priorities and statuses
                let origin1 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 1,
                    slug: "origin-1",
                    url: "https://test.com/origin-1",
                    referer: "https://test.com",
                    classification: .Safe,
                    status: .Completed, // lower priority has completed status
                    createdAt: Date(),
                    priority: 1
                )
                try origin1.insert(db)
                
                let origin2 = Domain.Models.Persistence.Origin(
                    sourceId: 1,
                    mangaId: 1,
                    slug: "origin-2",
                    url: "https://test.com/origin-2",
                    referer: "https://test.com",
                    classification: .Safe,
                    status: .Ongoing, // higher priority has ongoing status
                    createdAt: Date(),
                    priority: 0
                )
                try origin2.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.publishStatus = [.Ongoing]
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert - should find manga because highest priority origin is ongoing
            #expect(entries.count == 1)
            #expect(entries.first?.title == "Multi-Origin")
        }
        
        // MARK: - Reactive Updates Tests
        
        @Test("test_getLibrary_withReactiveUpdates_emitsOnLibraryChanges")
        func testReactiveLibraryUpdates() async throws {
            // arrange
            let filters = Domain.Models.Presentation.LibraryFilters()
            
            // create expectation for multiple emissions
            var emissions: [[Domain.Models.Virtual.Entry]] = []
            let expectation = AsyncStream<Void>.makeStream()
            
            // start observing
            let cancellable = dataSource.getLibrary(filters: filters, collectionId: nil)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { entries in
                        emissions.append(entries)
                        if emissions.count >= 2 {
                            expectation.continuation.finish()
                        }
                    }
                )
            
            // initial state - empty library
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // act - add manga to library
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest(title: "New Manga")
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            // wait for emissions
            for await _ in expectation.stream {
                break
            }
            
            // assert
            #expect(emissions.count >= 2)
            #expect(emissions[0].isEmpty) // initial empty state
            #expect(emissions[1].count == 1) // after adding manga
            #expect(emissions[1].first?.title == "New Manga")
            
            cancellable.cancel()
        }
        
        // MARK: - Edge Cases
        
        @Test("test_getLibrary_withWhitespaceSearch_trimsAndSearches")
        func testWhitespaceSearchHandling() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest(title: "One Piece")
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "  One  " // with extra whitespace
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.count == 1)
            #expect(entries.first?.title == "One Piece")
        }
        
        @Test("test_getLibrary_withInvalidSearchPattern_returnsEmptyResults")
        func testInvalidSearchPattern() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga.makeTest(title: "Test Manga")
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            var filters = Domain.Models.Presentation.LibraryFilters()
            filters.searchText = "***" // invalid FTS5 pattern
            
            // act
            let entries = try await dataSource.getLibrary(filters: filters, collectionId: nil)
                .async()
            
            // assert
            #expect(entries.isEmpty) // should return empty instead of crashing
        }
    }
}

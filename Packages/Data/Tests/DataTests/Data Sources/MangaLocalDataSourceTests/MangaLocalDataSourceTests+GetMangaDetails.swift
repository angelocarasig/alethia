//
//  MangaLocalDataSourceTests+GetMangaDetails.swift
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

// mock async()
private extension Publisher {
    func async() async throws -> Output {
        try await self
            .first()
            .values
            .first(where: { _ in true })!
    }
}

extension MangaLocalDataSourceTests {
    @Suite("GetMangaDetails Tests")
    struct GetMangaDetailsTests {
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
        
        @Test("test_getMangaDetails_withFTS5Search_matchesVariousPatterns")
        func testFTS5TitleSearch() async throws {
            // arrange
            try await database.write { db in
                // create manga with specific title
                var manga = Domain.Models.Persistence.Manga(
                    title: "Mayonaka Heart Tune",
                    synopsis: "Test manga"
                )
                manga.id = 1
                manga.inLibrary = true
                try manga.insert(db)
                
                // add alternative title
                try Domain.Models.Persistence.Title(
                    mangaId: 1,
                    title: "Midnight"
                ).insert(db)
            }
            
            // act & assert - exact match
            let exactEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "Mayonaka Heart Tune",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let exactResults = try await dataSource.getMangaDetails(entry: exactEntry).async()
            #expect(exactResults.count == 1)
            #expect(exactResults.first?.manga.title == "Mayonaka Heart Tune")
            
            // act & assert - partial word match
            let heartEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "Heart",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let heartResults = try await dataSource.getMangaDetails(entry: heartEntry).async()
            #expect(heartResults.count == 1)
            #expect(heartResults.first?.manga.title == "Mayonaka Heart Tune")
            
            // act & assert - prefix match
            let prefixEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "H",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let prefixResults = try await dataSource.getMangaDetails(entry: prefixEntry).async()
            #expect(prefixResults.count == 1)
            #expect(prefixResults.first?.manga.title == "Mayonaka Heart Tune")
            
            // act & assert - no match
            let noMatchEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "X",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let noMatchResults = try await dataSource.getMangaDetails(entry: noMatchEntry).async()
            #expect(noMatchResults.isEmpty)
            
            // act & assert - alternative title prefix match
            let altTitleEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "Mid",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let altTitleResults = try await dataSource.getMangaDetails(entry: altTitleEntry).async()
            #expect(altTitleResults.count == 1)
            #expect(altTitleResults.first?.manga.title == "Mayonaka Heart Tune")
            
            // verify the alternative title was loaded
            #expect(altTitleResults.first?.titles.contains { $0.title == "Midnight" } == true)
        }
        
        @Test("test_getMangaDetails_withFTS5_handlesCaseInsensitiveSearch")
        func testFTS5CaseInsensitive() async throws {
            // arrange
            try await database.write { db in
                var manga = Domain.Models.Persistence.Manga(
                    title: "Attack on Titan",
                    synopsis: "Test manga"
                )
                manga.id = 1
                manga.inLibrary = true
                try manga.insert(db)
            }
            
            // act - lowercase search
            let lowercaseEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "attack",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let results = try await dataSource.getMangaDetails(entry: lowercaseEntry).async()
            
            // assert
            #expect(results.count == 1)
            #expect(results.first?.manga.title == "Attack on Titan")
        }
        
        @Test("test_getMangaDetails_withFTS5_matchesMultipleWords")
        func testFTS5MultiWordSearch() async throws {
            // arrange
            try await database.write { db in
                // create multiple manga
                var manga1 = Domain.Models.Persistence.Manga(
                    title: "One Piece",
                    synopsis: "Pirates"
                )
                manga1.id = 1
                manga1.inLibrary = true
                try manga1.insert(db)
                
                var manga2 = Domain.Models.Persistence.Manga(
                    title: "One Punch Man",
                    synopsis: "Hero"
                )
                manga2.id = 2
                manga2.inLibrary = true
                try manga2.insert(db)
                
                var manga3 = Domain.Models.Persistence.Manga(
                    title: "Piece of Cake",
                    synopsis: "Romance"
                )
                manga3.id = 3
                manga3.inLibrary = true
                try manga3.insert(db)
            }
            
            // act - search for "One Piece" (should match all tokens)
            let entry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "One Piece",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let results = try await dataSource.getMangaDetails(entry: entry).async()
            
            // assert - should only find exact "One Piece" with FTS5Pattern(matchingAllTokensIn:)
            #expect(results.count == 1)
            #expect(results.first?.manga.title == "One Piece")
        }
        
        @Test("test_getMangaDetails_withFTS5_failsOnNonPrefixes")
        func testFTS5FailsOnNonPrefixes() async throws {
            // arrange
            try await database.write { db in
                // create manga with specific title
                var manga = Domain.Models.Persistence.Manga(
                    title: "Mayonaka Heart Tune",
                    synopsis: "Test manga"
                )
                manga.id = 1
                manga.inLibrary = true
                try manga.insert(db)
                
                // add alternative title
                try Domain.Models.Persistence.Title(
                    mangaId: 1,
                    title: "Midnight"
                ).insert(db)
            }
            
            // act - search for "ear" (substring of the 'heart' in stubbed manga title)
            let entry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "ear",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let results = try await dataSource.getMangaDetails(entry: entry).async()
            
            // assert - should return none
            #expect(results.count == 0)
        }
        
        @Test("test_getMangaDetails_withFTS5_handlesDiacritics")
        func testFTS5DiacriticsHandling() async throws {
            // arrange
            try await database.write { db in
                // create manga with accented characters
                var manga1 = Domain.Models.Persistence.Manga(
                    title: "Café au Lait",
                    synopsis: "A story about coffee"
                )
                manga1.id = 1
                manga1.inLibrary = true
                try manga1.insert(db)
                
                // create manga with different diacritics
                var manga2 = Domain.Models.Persistence.Manga(
                    title: "Naïve Résumé",
                    synopsis: "A story about job hunting"
                )
                manga2.id = 2
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // add alternative title with diacritics
                try Domain.Models.Persistence.Title(
                    mangaId: 1,
                    title: "Café et Crème"
                ).insert(db)
                
                // add alternative title without diacritics for comparison
                try Domain.Models.Persistence.Title(
                    mangaId: 2,
                    title: "Naive Resume"
                ).insert(db)
            }
            
            // act & assert - search without diacritics should find accented version
            let cafeEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "cafe", // no accent
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let cafeResults = try await dataSource.getMangaDetails(entry: cafeEntry).async()
            #expect(cafeResults.count == 1)
            #expect(cafeResults.first?.manga.title == "Café au Lait")
            
            // act & assert - search with different accent should still find
            let cafeAccentEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "cafè", // different accent
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let cafeAccentResults = try await dataSource.getMangaDetails(entry: cafeAccentEntry).async()
            #expect(cafeAccentResults.count == 1)
            #expect(cafeAccentResults.first?.manga.title == "Café au Lait")
            
            // act & assert - search for "naive" should find "Naïve"
            let naiveEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "naive",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let naiveResults = try await dataSource.getMangaDetails(entry: naiveEntry).async()
            #expect(naiveResults.count == 1)
            #expect(naiveResults.first?.manga.title == "Naïve Résumé")
            
            // act & assert - search for "resume" should find "Résumé"
            let resumeEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "resume",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let resumeResults = try await dataSource.getMangaDetails(entry: resumeEntry).async()
            #expect(resumeResults.count == 1)
            #expect(resumeResults.first?.manga.title == "Naïve Résumé")
            
            // act & assert - partial match with diacritics
            let creamEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "creme", // searching without accent
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let creamResults = try await dataSource.getMangaDetails(entry: creamEntry).async()
            #expect(creamResults.count == 1)
            #expect(creamResults.first?.manga.id == 1)
            // verify alternative title was loaded
            #expect(creamResults.first?.titles.contains { $0.title == "Café et Crème" } == true)
            
            // act & assert - prefix search with diacritics
            let naEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "na", // prefix of "Naïve"
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let naResults = try await dataSource.getMangaDetails(entry: naEntry).async()
            #expect(naResults.count == 1)
            #expect(naResults.first?.manga.title == "Naïve Résumé")
            
            // act & assert - search with accented prefix should also work
            let naAccentEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "naï", // prefix with accent
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let naAccentResults = try await dataSource.getMangaDetails(entry: naAccentEntry).async()
            #expect(naAccentResults.count == 1)
            #expect(naAccentResults.first?.manga.title == "Naïve Résumé")
        }
        
        @Test("test_getMangaDetails_withFTS5_handlesSpecialCharactersAndDiacritics")
        func testFTS5SpecialCharactersWithDiacritics() async throws {
            // arrange
            try await database.write { db in
                // create manga with special characters and diacritics
                var manga1 = Domain.Models.Persistence.Manga(
                    title: "L'Étoile du Nord",
                    synopsis: "A story about stars"
                )
                manga1.id = 1
                manga1.inLibrary = true
                try manga1.insert(db)
                
                // create manga with combined diacritics
                var manga2 = Domain.Models.Persistence.Manga(
                    title: "Pokémon: Les Aventures",
                    synopsis: "Pokemon adventures"
                )
                manga2.id = 2
                manga2.inLibrary = true
                try manga2.insert(db)
                
                // add alternative titles
                try Domain.Models.Persistence.Title(
                    mangaId: 1,
                    title: "L'Etoile" // without accents
                ).insert(db)
            }
            
            // act & assert - search for "etoile" should find "Étoile"
            let etoileEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "etoile",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let etoileResults = try await dataSource.getMangaDetails(entry: etoileEntry).async()
            #expect(etoileResults.count == 1)
            #expect(etoileResults.first?.manga.title == "L'Étoile du Nord")
            
            // act & assert - search for "pokemon" should find "Pokémon"
            let pokemonEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "pokemon",
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let pokemonResults = try await dataSource.getMangaDetails(entry: pokemonEntry).async()
            #expect(pokemonResults.count == 1)
            #expect(pokemonResults.first?.manga.title == "Pokémon: Les Aventures")
            
            // act & assert - partial word search ignoring apostrophe and accent is not a diacritic and should fail on L'Étoile
            let letoileEntry = Domain.Models.Virtual.Entry(
                mangaId: nil,
                sourceId: nil,
                title: "Letoile", // no apostrophe or accent
                slug: "test",
                cover: "",
                inLibrary: false
            )
            
            let letoileResults = try await dataSource.getMangaDetails(entry: letoileEntry).async()
            #expect(letoileResults.count == 0)
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
}

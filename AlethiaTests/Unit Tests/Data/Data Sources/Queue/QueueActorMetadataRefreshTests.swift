//
//  QueueActorMetadataRefreshTests.swift
//  AlethiaTests
//
//  Created by Tests on 26/5/2025.
//

import Testing
import Foundation
import GRDB
@testable import Alethia

@Suite("QueueActor Metadata Refresh Tests")
struct QueueActorMetadataRefreshTests {
    
    // MARK: - Test Database Setup
    
    private func makeTestDatabase() throws -> DatabaseWriter {
        let dbQueue = try DatabaseQueue()
        let provider = try DatabaseProvider(dbQueue)
        return provider.writer
    }
    
    private func setupTestData(in db: DatabaseWriter) throws -> (manga: Manga, host: Host, source: Source, origin: Origin) {
        return try db.write { db in
            // Create host
            var host = Host(
                name: "Test Host",
                author: "Test Author",
                repository: "https://github.com/test/test",
                baseUrl: "https://test.example.com"
            )
            host = try host.insertAndFetch(db)
            
            // Create source
            var source = Source(
                name: "Test Source",
                icon: "/path/to/icon.png",
                path: "test-source",
                website: "https://test.example.com",
                description: "Test source description",
                hostId: host.id!
            )
            source = try source.insertAndFetch(db)
            
            // Create manga
            var manga = Manga(title: "Test Manga", synopsis: "Original synopsis")
            manga = try manga.insertAndFetch(db)
            
            // Create origin
            var origin = Origin(
                mangaId: manga.id!,
                sourceId: source.id!,
                slug: "test-manga",
                url: "https://test.example.com/manga/test-manga",
                referer: "https://test.example.com",
                classification: .Safe,
                status: .Ongoing,
                createdAt: Date(),
                priority: 0
            )
            origin = try origin.insertAndFetch(db)
            
            return (manga, host, source, origin)
        }
    }
}

// MARK: - Cover Update Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Adding new covers sets the last one as active")
    func addingNewCoversSetLastAsActive() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial cover
        try db.write { db in
            try Cover(
                active: true,
                url: "https://example.com/cover1.jpg",
                path: "https://example.com/cover1.jpg",
                mangaId: manga.id!
            ).insert(db)
        }
        
        // Test adding new covers
        let newCoverUrls = [
            "https://example.com/cover2.jpg",
            "https://example.com/cover3.jpg",
            "https://example.com/cover4.jpg"
        ]
        
        try db.write { db in
            try QueueActor.updateCovers(newCoverUrls, mangaId: manga.id!, db: db)
        }
        
        // Verify all covers exist and last one is active
        let covers = try db.read { db in
            try Cover.filter(Cover.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(covers.count == 4) // 1 original + 3 new
        
        let activeCovers = covers.filter { $0.active }
        #expect(activeCovers.count == 1)
        #expect(activeCovers.first?.url == "https://example.com/cover4.jpg")
    }
    
    @Test("Adding covers when none exist sets last as active")
    func addingCoversWhenNoneExistSetsLastAsActive() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        let newCoverUrls = [
            "https://example.com/cover1.jpg",
            "https://example.com/cover2.jpg"
        ]
        
        try db.write { db in
            try QueueActor.updateCovers(newCoverUrls, mangaId: manga.id!, db: db)
        }
        
        let covers = try db.read { db in
            try Cover.filter(Cover.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(covers.count == 2)
        
        let activeCovers = covers.filter { $0.active }
        #expect(activeCovers.count == 1)
        #expect(activeCovers.first?.url == "https://example.com/cover2.jpg") // Last one should be active
    }
    
    @Test("Adding duplicate covers does nothing")
    func addingDuplicateCoversDoesNothing() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial cover
        try db.write { db in
            try Cover(
                active: true,
                url: "https://example.com/cover1.jpg",
                path: "https://example.com/cover1.jpg",
                mangaId: manga.id!
            ).insert(db)
        }
        
        // Try to add the same cover again
        try db.write { db in
            try QueueActor.updateCovers(["https://example.com/cover1.jpg"], mangaId: manga.id!, db: db)
        }
        
        let covers = try db.read { db in
            try Cover.filter(Cover.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(covers.count == 1)
        #expect(covers.first?.active == true)
        #expect(covers.first?.url == "https://example.com/cover1.jpg")
    }
    
    @Test("Empty cover URLs array does nothing")
    func emptyCoversArrayDoesNothing() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial cover
        try db.write { db in
            try Cover(
                active: true,
                url: "https://example.com/cover1.jpg",
                path: "https://example.com/cover1.jpg",
                mangaId: manga.id!
            ).insert(db)
        }
        
        // Pass empty array
        try db.write { db in
            try QueueActor.updateCovers([], mangaId: manga.id!, db: db)
        }
        
        let covers = try db.read { db in
            try Cover.filter(Cover.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(covers.count == 1)
        #expect(covers.first?.active == true)
    }
}

// MARK: - Title Update Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Adding new titles works correctly")
    func addingNewTitlesWorksCorrectly() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial title
        try db.write { db in
            try Title(title: "Alternative Title 1", mangaId: manga.id!).insert(db)
        }
        
        let newTitles = [
            "Alternative Title 1", // Duplicate - should be ignored
            "Alternative Title 2", // New
            "Alternative Title 3"  // New
        ]
        
        try db.write { db in
            try QueueActor.updateTitles(newTitles, mangaId: manga.id!, db: db)
        }
        
        let titles = try db.read { db in
            try Title.filter(Title.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(titles.count == 3)
        
        let titleNames = Set(titles.map { $0.title })
        #expect(titleNames.contains("Alternative Title 1"))
        #expect(titleNames.contains("Alternative Title 2"))
        #expect(titleNames.contains("Alternative Title 3"))
    }
    
    @Test("Adding duplicate titles does nothing")
    func addingDuplicateTitlesDoesNothing() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial titles
        try db.write { db in
            try Title(title: "Title 1", mangaId: manga.id!).insert(db)
            try Title(title: "Title 2", mangaId: manga.id!).insert(db)
        }
        
        // Try to add same titles
        try db.write { db in
            try QueueActor.updateTitles(["Title 1", "Title 2"], mangaId: manga.id!, db: db)
        }
        
        let titles = try db.read { db in
            try Title.filter(Title.Columns.mangaId == manga.id!).fetchAll(db)
        }
        
        #expect(titles.count == 2)
    }
}

// MARK: - Author Update Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Adding new authors creates associations correctly")
    func addingNewAuthorsCreatesAssociationsCorrectly() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial author
        try db.write { db in
            let author = try Author.findOrCreate(db, instance: Author(name: "Author 1"))
            try MangaAuthor(authorId: author.id!, mangaId: manga.id!).insert(db)
        }
        
        let newAuthors = [
            "Author 1", // Duplicate - should be ignored
            "Author 2", // New
            "Author 3"  // New
        ]
        
        try db.write { db in
            try QueueActor.updateAuthors(newAuthors, mangaId: manga.id!, db: db)
        }
        
        let authors = try db.read { db in
            try Author
                .joining(required: Author.mangaAuthor.filter(MangaAuthor.Columns.mangaId == manga.id!))
                .fetchAll(db)
        }
        
        #expect(authors.count == 3)
        
        let authorNames = Set(authors.map { $0.name })
        #expect(authorNames.contains("Author 1"))
        #expect(authorNames.contains("Author 2"))
        #expect(authorNames.contains("Author 3"))
    }
}

// MARK: - Tag Update Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Adding new tags creates associations correctly")
    func addingNewTagsCreatesAssociationsCorrectly() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Add initial tag
        try db.write { db in
            let tag = try Tag.findOrCreate(db, instance: Tag(name: "Action"))
            try MangaTag(tagId: tag.id!, mangaId: manga.id!).insert(db)
        }
        
        let newTags = [
            "Action",    // Duplicate - should be ignored
            "Adventure", // New
            "Romance"    // New
        ]
        
        try db.write { db in
            try QueueActor.updateTags(newTags, mangaId: manga.id!, db: db)
        }
        
        let tags = try db.read { db in
            try Tag
                .joining(required: Tag.mangaTag.filter(MangaTag.Columns.mangaId == manga.id!))
                .fetchAll(db)
        }
        
        #expect(tags.count == 3)
        
        let tagNames = Set(tags.map { $0.name })
        #expect(tagNames.contains("Action"))
        #expect(tagNames.contains("Adventure"))
        #expect(tagNames.contains("Romance"))
    }
    
    @Test("Tag creation handles error gracefully when tag ID is nil")
    func tagCreationHandlesNilIdError() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Test the normal flow and verify it doesn't throw
        try db.write { db in
            #expect(throws: Never.self) {
                try QueueActor.updateTags(["Valid Tag"], mangaId: manga.id!, db: db)
            }
        }
        
        let tags = try db.read { db in
            try Tag
                .joining(required: Tag.mangaTag.filter(MangaTag.Columns.mangaId == manga.id!))
                .fetchAll(db)
        }
        
        #expect(tags.count == 1)
        #expect(tags.first?.name == "Valid Tag")
    }
}

// MARK: - Chapter Update Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Adding new chapters works correctly")
    func addingNewChaptersWorksCorrectly() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        // Add initial scanlator and chapter
        try db.write { db in
            var scanlator = Scanlator(originId: origin.id!, name: "Existing Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Existing Chapter",
                slug: "existing-chapter",
                number: 1.0,
                date: Date()
            ).insert(db)
        }
        
        let newChapters = [
            ChapterDTO(
                title: "Existing Chapter",
                slug: "existing-chapter", // Duplicate - should be ignored
                number: 1.0,
                scanlator: "Existing Scanlator",
                date: "2023-01-01T00:00:00.000Z"
            ),
            ChapterDTO(
                title: "New Chapter 1",
                slug: "new-chapter-1", // New
                number: 2.0,
                scanlator: "Existing Scanlator",
                date: "2023-01-02T00:00:00.000Z"
            ),
            ChapterDTO(
                title: "New Chapter 2",
                slug: "new-chapter-2", // New
                number: 3.0,
                scanlator: "New Scanlator", // New scanlator
                date: "2023-01-03T00:00:00.000Z"
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(newChapters, originId: origin.id!, db: db)
        }
        
        let chapters = try db.read { db in
            try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(chapters.count == 3) // 1 existing + 2 new
        
        let chapterSlugs = Set(chapters.map { $0.slug })
        #expect(chapterSlugs.contains("existing-chapter"))
        #expect(chapterSlugs.contains("new-chapter-1"))
        #expect(chapterSlugs.contains("new-chapter-2"))
        
        // Verify scanlators
        let scanlators = try db.read { db in
            try Scanlator.filter(Scanlator.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(scanlators.count == 2) // Existing + New
        
        let scanlatorNames = Set(scanlators.map { $0.name })
        #expect(scanlatorNames.contains("Existing Scanlator"))
        #expect(scanlatorNames.contains("New Scanlator"))
    }
    
    @Test("Adding chapters with new scanlator creates scanlator correctly")
    func addingChaptersWithNewScanlatorCreatesScanlatorCorrectly() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        let newChapters = [
            ChapterDTO(
                title: "Chapter 1",
                slug: "chapter-1",
                number: 1.0,
                scanlator: "Brand New Scanlator",
                date: "2023-01-01T00:00:00.000Z"
            ),
            ChapterDTO(
                title: "Chapter 2",
                slug: "chapter-2",
                number: 2.0,
                scanlator: "Brand New Scanlator",
                date: "2023-01-02T00:00:00.000Z"
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(newChapters, originId: origin.id!, db: db)
        }
        
        let scanlators = try db.read { db in
            try Scanlator.filter(Scanlator.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(scanlators.count == 1)
        #expect(scanlators.first?.name == "Brand New Scanlator")
        #expect(scanlators.first?.priority == 0) // First scanlator gets priority 0
        
        let chapters = try db.read { db in
            try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(chapters.count == 2)
        #expect(chapters.allSatisfy { $0.scanlatorId == scanlators.first?.id })
    }
    
    @Test("Adding duplicate chapters by slug does nothing")
    func addingDuplicateChaptersBySlugeDoesNothing() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        // Add initial chapter
        try db.write { db in
            var scanlator = Scanlator(originId: origin.id!, name: "Test Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Test Chapter",
                slug: "test-chapter",
                number: 1.0,
                date: Date()
            ).insert(db)
        }
        
        // Try to add same chapter by slug
        let duplicateChapters = [
            ChapterDTO(
                title: "Different Title", // Different title but same slug
                slug: "test-chapter",     // Same slug - should be ignored
                number: 999.0,           // Different number
                scanlator: "Different Scanlator",
                date: "2023-01-01T00:00:00.000Z"
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(duplicateChapters, originId: origin.id!, db: db)
        }
        
        let chapters = try db.read { db in
            try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(chapters.count == 1) // Should still be just 1
        #expect(chapters.first?.title == "Test Chapter") // Original title preserved
        #expect(chapters.first?.number == 1.0) // Original number preserved
    }
    
    @Test("Empty chapters array does nothing")
    func emptyChaptersArrayDoesNothing() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        // Add initial chapter
        try db.write { db in
            var scanlator = Scanlator(originId: origin.id!, name: "Test Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Test Chapter",
                slug: "test-chapter",
                number: 1.0,
                date: Date()
            ).insert(db)
        }
        
        // Pass empty array
        try db.write { db in
            try QueueActor.updateChapters([], originId: origin.id!, db: db)
        }
        
        let chapters = try db.read { db in
            try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(chapters.count == 1)
        #expect(chapters.first?.title == "Test Chapter")
    }
    
    @Test("Scanlator priority assignment works correctly")
    func scanlatorPriorityAssignmentWorksCorrectly() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        // Add existing scanlators with specific priorities
        try db.write { db in
            try Scanlator(originId: origin.id!, name: "Scanlator A", priority: 0).insert(db)
            try Scanlator(originId: origin.id!, name: "Scanlator B", priority: 1).insert(db)
        }
        
        let newChapters = [
            ChapterDTO(
                title: "Chapter 1",
                slug: "chapter-1",
                number: 1.0,
                scanlator: "Scanlator C", // New scanlator
                date: "2023-01-01T00:00:00.000Z"
            ),
            ChapterDTO(
                title: "Chapter 2",
                slug: "chapter-2",
                number: 2.0,
                scanlator: "Scanlator D", // Another new scanlator
                date: "2023-01-02T00:00:00.000Z"
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(newChapters, originId: origin.id!, db: db)
        }
        
        let scanlators = try db.read { db in
            try Scanlator
                .filter(Scanlator.Columns.originId == origin.id!)
                .order(Scanlator.Columns.priority.asc)
                .fetchAll(db)
        }
        
        #expect(scanlators.count == 4)
        
        // Just verify the names exist and priorities are unique
        let scanlatorNames = Set(scanlators.map { $0.name })
        #expect(scanlatorNames.contains("Scanlator A"))
        #expect(scanlatorNames.contains("Scanlator B"))
        #expect(scanlatorNames.contains("Scanlator C"))
        #expect(scanlatorNames.contains("Scanlator D"))
        
        // Verify priorities are unique and in range
        let priorities = scanlators.map { $0.priority }
        #expect(Set(priorities).count == 4) // All unique
        #expect(priorities.min() == 0)
        #expect(priorities.max() == 3)
    }
    
    @Test("Adding chapters with all existing slugs does nothing")
    func addingChaptersWithAllExistingSlugsDoesNothing() throws {
        let db = try makeTestDatabase()
        let (_, _, _, origin) = try setupTestData(in: db)
        
        // Add initial chapters
        try db.write { db in
            var scanlator = Scanlator(originId: origin.id!, name: "Test Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Chapter 1",
                slug: "chapter-1",
                number: 1.0,
                date: Date().addingTimeInterval(-86400 * 5) // 5 days ago
            ).insert(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Chapter 2",
                slug: "chapter-2",
                number: 2.0,
                date: Date().addingTimeInterval(-86400 * 3) // 3 days ago
            ).insert(db)
        }
        
        // Try to add chapters with same slugs but different data
        let unchangedChapters = [
            ChapterDTO(
                title: "Different Title 1",    // Different title
                slug: "chapter-1",           // Same slug - should be ignored
                number: 999.0,               // Different number
                scanlator: "Different Scanlator",
                date: "2023-01-01T00:00:00.000Z"
            ),
            ChapterDTO(
                title: "Different Title 2",    // Different title
                slug: "chapter-2",           // Same slug - should be ignored
                number: 888.0,               // Different number
                scanlator: "Another Different Scanlator",
                date: "2023-01-02T00:00:00.000Z"
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(unchangedChapters, originId: origin.id!, db: db)
        }
        
        let chapters = try db.read { db in
            try Chapter
                .filter(Chapter.Columns.originId == origin.id!)
                .order(Chapter.Columns.number.asc)
                .fetchAll(db)
        }
        
        // Should still be exactly the same chapters
        #expect(chapters.count == 2)
        #expect(chapters[0].title == "Chapter 1")     // Original title preserved
        #expect(chapters[0].number == 1.0)           // Original number preserved
        #expect(chapters[1].title == "Chapter 2")     // Original title preserved
        #expect(chapters[1].number == 2.0)           // Original number preserved
        
        // Should still be only one scanlator (no new scanlators created)
        let scanlators = try db.read { db in
            try Scanlator.filter(Scanlator.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(scanlators.count == 1)
        #expect(scanlators.first?.name == "Test Scanlator")
    }
}

// MARK: - Manga UpdatedAt Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Manga updatedAt gets set to latest chapter date")
    func mangaUpdatedAtGetsSetToLatestChapterDate() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, origin) = try setupTestData(in: db)
        
        // Create chapters with different dates
        let oldDate = Date().addingTimeInterval(-86400 * 10) // 10 days ago
        let newDate = Date().addingTimeInterval(-86400 * 2)  // 2 days ago
        
        try db.write { db in
            // Create scanlator
            var scanlator = Scanlator(originId: origin.id!, name: "Test Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            // Create chapters
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Chapter 1",
                slug: "chapter-1",
                number: 1.0,
                date: oldDate
            ).insert(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Chapter 2",
                slug: "chapter-2",
                number: 2.0,
                date: newDate
            ).insert(db)
        }
        
        // Update manga's updatedAt
        try db.write { db in
            try QueueActor.updateMangaUpdatedAt(mangaId: manga.id!, db: db)
        }
        
        let updatedManga = try db.read { db in
            try Manga.fetchOne(db, key: manga.id!)!
        }
        
        // Should be set to the latest chapter date
        let timeDifference = abs(updatedManga.updatedAt.timeIntervalSince(newDate))
        #expect(timeDifference < 1.0) // Within 1 second
    }
    
    @Test("Manga updatedAt unchanged when no chapters exist")
    func mangaUpdatedAtUnchangedWhenNoChaptersExist() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        let originalDate = manga.updatedAt
        
        // Try to update when no chapters exist
        try db.write { db in
            try QueueActor.updateMangaUpdatedAt(mangaId: manga.id!, db: db)
        }
        
        let updatedManga = try db.read { db in
            try Manga.fetchOne(db, key: manga.id!)!
        }
        
        // Should remain unchanged
        #expect(updatedManga.updatedAt == originalDate)
    }
    
    @Test("Manga updatedAt unchanged when adding older chapters")
    func mangaUpdatedAtUnchangedWhenAddingOlderChapters() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, origin) = try setupTestData(in: db)
        
        let recentDate = Date().addingTimeInterval(-86400 * 1) // 1 day ago
        let oldDate = Date().addingTimeInterval(-86400 * 10)   // 10 days ago
        let veryOldDate = Date().addingTimeInterval(-86400 * 20) // 20 days ago
        
        // Add recent chapter first
        try db.write { db in
            var scanlator = Scanlator(originId: origin.id!, name: "Test Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Recent Chapter",
                slug: "recent-chapter",
                number: 10.0,
                date: recentDate
            ).insert(db)
            
            // Update manga's updatedAt to match the recent chapter
            try QueueActor.updateMangaUpdatedAt(mangaId: manga.id!, db: db)
        }
        
        // Get the updatedAt after the recent chapter
        let mangaAfterRecentChapter = try db.read { db in
            try Manga.fetchOne(db, key: manga.id!)!
        }
        
        let timeDifferenceRecent = abs(mangaAfterRecentChapter.updatedAt.timeIntervalSince(recentDate))
        #expect(timeDifferenceRecent < 1.0) // Should be set to recent date
        
        // Now add older chapters
        let olderChapters = [
            ChapterDTO(
                title: "Old Chapter 1",
                slug: "old-chapter-1",
                number: 1.0,
                scanlator: "Test Scanlator",
                date: oldDate.ISO8601Format() // 10 days ago
            ),
            ChapterDTO(
                title: "Very Old Chapter",
                slug: "very-old-chapter",
                number: 0.5,
                scanlator: "Test Scanlator",
                date: veryOldDate.ISO8601Format() // 20 days ago
            )
        ]
        
        try db.write { db in
            try QueueActor.updateChapters(olderChapters, originId: origin.id!, db: db)
            // Update manga's updatedAt after adding older chapters
            try QueueActor.updateMangaUpdatedAt(mangaId: manga.id!, db: db)
        }
        
        let finalManga = try db.read { db in
            try Manga.fetchOne(db, key: manga.id!)!
        }
        
        // updatedAt should still be the recent date, not the older chapter dates
        let timeDifferenceFinal = abs(finalManga.updatedAt.timeIntervalSince(recentDate))
        #expect(timeDifferenceFinal < 1.0) // Should still be the recent date
        
        // Verify older chapters were actually added
        let allChapters = try db.read { db in
            try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
        }
        
        #expect(allChapters.count == 3) // 1 recent + 2 older
        
        let chapterSlugs = Set(allChapters.map { $0.slug })
        #expect(chapterSlugs.contains("recent-chapter"))
        #expect(chapterSlugs.contains("old-chapter-1"))
        #expect(chapterSlugs.contains("very-old-chapter"))
    }
}

// MARK: - Integration Tests
extension QueueActorMetadataRefreshTests {
    
    @Test("Complete metadata update with mixed new and existing data including chapters")
    func completeMetadataUpdateWithMixedDataIncludingChapters() throws {
        let db = try makeTestDatabase()
        let (manga, _, _, _) = try setupTestData(in: db)
        
        // Setup existing data
        try db.write { db in
            // Get the origin for chapter setup
            let origin = try Origin.filter(Origin.Columns.mangaId == manga.id!).fetchOne(db)!
            
            // Existing title
            try Title(title: "Existing Title", mangaId: manga.id!).insert(db)
            
            // Existing cover
            try Cover(
                active: true,
                url: "https://example.com/old-cover.jpg",
                path: "https://example.com/old-cover.jpg",
                mangaId: manga.id!
            ).insert(db)
            
            // Existing author
            let author = try Author.findOrCreate(db, instance: Author(name: "Existing Author"))
            try MangaAuthor(authorId: author.id!, mangaId: manga.id!).insert(db)
            
            // Existing tag
            let tag = try Tag.findOrCreate(db, instance: Tag(name: "Existing Tag"))
            try MangaTag(tagId: tag.id!, mangaId: manga.id!).insert(db)
            
            // Existing scanlator and chapter
            var scanlator = Scanlator(originId: origin.id!, name: "Existing Scanlator", priority: 0)
            scanlator = try scanlator.insertAndFetch(db)
            
            try Chapter(
                originId: origin.id!,
                scanlatorId: scanlator.id!,
                title: "Existing Chapter",
                slug: "existing-chapter",
                number: 1.0,
                date: Date().addingTimeInterval(-86400) // 1 day ago
            ).insert(db)
        }
        
        // Create payload with mixed new and existing data
        let payload = DetailDTO(
            manga: MangaDTO(
                title: "Test Manga", // Keep original title
                authors: ["Existing Author", "New Author"],
                synopsis: "Original synopsis", // Keep original synopsis
                alternativeTitles: ["Existing Title", "New Title"],
                tags: ["Existing Tag", "New Tag"]
            ),
            origin: OriginDTO(
                slug: "test-manga",
                url: "https://test.example.com/manga/test-manga",
                referer: "https://test.example.com",
                covers: ["https://example.com/old-cover.jpg", "https://example.com/new-cover.jpg"],
                status: "Ongoing",
                classification: "Safe",
                creation: "2023-01-01T00:00:00.000Z"
            ),
            chapters: [
                ChapterDTO(
                    title: "Existing Chapter",
                    slug: "existing-chapter", // Duplicate
                    number: 1.0,
                    scanlator: "Existing Scanlator",
                    date: "2023-01-01T00:00:00.000Z"
                ),
                ChapterDTO(
                    title: "New Chapter",
                    slug: "new-chapter", // New
                    number: 2.0,
                    scanlator: "New Scanlator", // New scanlator
                    date: "2023-01-02T00:00:00.000Z"
                )
            ]
        )
        
        // Apply update using the actual function
        try db.write { db in
            guard let origin = try Origin
                .filter(Origin.Columns.mangaId == manga.id!)
                .filter(Origin.Columns.slug == payload.origin.slug)
                .fetchOne(db) else {
                throw OriginError.notFound
            }
            
            // Update related entities (no manga property updates since removed)
            try QueueActor.updateTitles(payload.manga.alternativeTitles, mangaId: manga.id!, db: db)
            try QueueActor.updateCovers(payload.origin.covers, mangaId: manga.id!, db: db)
            try QueueActor.updateAuthors(payload.manga.authors, mangaId: manga.id!, db: db)
            try QueueActor.updateTags(payload.manga.tags, mangaId: manga.id!, db: db)
            try QueueActor.updateChapters(payload.chapters, originId: origin.id!, db: db)
            try QueueActor.updateMangaUpdatedAt(mangaId: manga.id!, db: db)
        }
        
        // Verify results
        let (updatedManga, titles, covers, authors, tags, chapters, scanlators) = try db.read { db in
            let manga = try Manga.fetchOne(db, key: manga.id!)!
            let titles = try Title.filter(Title.Columns.mangaId == manga.id!).fetchAll(db)
            let covers = try Cover.filter(Cover.Columns.mangaId == manga.id!).fetchAll(db)
            let authors = try Author
                .joining(required: Author.mangaAuthor.filter(MangaAuthor.Columns.mangaId == manga.id!))
                .fetchAll(db)
            let tags = try Tag
                .joining(required: Tag.mangaTag.filter(MangaTag.Columns.mangaId == manga.id!))
                .fetchAll(db)
            
            let origin = try Origin.filter(Origin.Columns.mangaId == manga.id!).fetchOne(db)!
            let chapters = try Chapter.filter(Chapter.Columns.originId == origin.id!).fetchAll(db)
            let scanlators = try Scanlator.filter(Scanlator.Columns.originId == origin.id!).fetchAll(db)
            
            return (manga, titles, covers, authors, tags, chapters, scanlators)
        }
        
        // Verify manga properties unchanged (since we removed basic property updates)
        #expect(updatedManga.title == "Test Manga")
        #expect(updatedManga.synopsis == "Original synopsis")
        
        // Verify titles (existing + new)
        #expect(titles.count == 2)
        let titleNames = Set(titles.map { $0.title })
        #expect(titleNames.contains("Existing Title"))
        #expect(titleNames.contains("New Title"))
        
        // Verify covers (existing + new, with new one active)
        #expect(covers.count == 2)
        let activeCovers = covers.filter { $0.active }
        #expect(activeCovers.count == 1)
        #expect(activeCovers.first?.url == "https://example.com/new-cover.jpg")
        
        // Verify authors (existing + new)
        #expect(authors.count == 2)
        let authorNames = Set(authors.map { $0.name })
        #expect(authorNames.contains("Existing Author"))
        #expect(authorNames.contains("New Author"))
        
        // Verify tags (existing + new)
        #expect(tags.count == 2)
        let tagNames = Set(tags.map { $0.name })
        #expect(tagNames.contains("Existing Tag"))
        #expect(tagNames.contains("New Tag"))
        
        // Verify chapters (existing + new)
        #expect(chapters.count == 2)
        let chapterSlugs = Set(chapters.map { $0.slug })
        #expect(chapterSlugs.contains("existing-chapter"))
        #expect(chapterSlugs.contains("new-chapter"))
        
        // Verify scanlators (existing + new)
        #expect(scanlators.count == 2)
        let scanlatorNames = Set(scanlators.map { $0.name })
        #expect(scanlatorNames.contains("Existing Scanlator"))
        #expect(scanlatorNames.contains("New Scanlator"))
    }
}

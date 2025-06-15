//
//  DatabaseMocks.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import Foundation
import GRDB
import Domain
@testable import Data

// in-memory database for testing
func makeTestDatabase() throws -> DatabaseWriter {
    let provider = Data.Infrastructure.DatabaseProvider.makeTest()
    return provider.writer
}

// test data builders
extension Domain.Models.Persistence.Manga {
    static func makeTest(
        id: Int64? = 1,
        title: String = "Test Manga",
        synopsis: String = "Test synopsis"
    ) -> Self {
        var manga = Self(title: title, synopsis: synopsis)
        manga.id = id
        manga.inLibrary = true
        return manga
    }
}

extension Domain.Models.Persistence.Chapter {
    static func makeTest(
        id: Int64? = 1,
        originId: Int64 = 1,
        scanlatorId: Int64 = 1,
        number: Double = 1.0
    ) -> Self {
        Self(
            id: id,
            originId: originId,
            scanlatorId: scanlatorId,
            title: "Chapter \(number)",
            slug: "chapter-\(number)",
            number: number,
            date: Date(),
            progress: 0.0
        )
    }
}

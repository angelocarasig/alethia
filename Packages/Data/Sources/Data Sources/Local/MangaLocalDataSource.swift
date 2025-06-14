//
//  MangaLocalDataSource.swift
//  Data
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation
import Domain
import Combine
import GRDB

internal typealias MangaLocalDataSource = Data.DataSources.MangaLocalDataSource
internal typealias Entry = Domain.Models.Virtual.Entry
internal typealias Details = Domain.Models.Virtual.Details

public extension Data.DataSources {
    final class MangaLocalDataSource {
    }
}

internal extension MangaLocalDataSource {
    func getMangaDetails(entry: Entry) -> AnyPublisher<[Details], Error> {
        return ValueObservation.tracking { [weak self] db -> [Details] in
            return []
        }
        .publisher(in: database, scheduling: .immediate)
        .eraseToAnyPublisher()
    }
}

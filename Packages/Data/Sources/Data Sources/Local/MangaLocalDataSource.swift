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

private typealias MangaLocalDataSource = Data.DataSources.MangaLocalDataSource
private typealias Details = Domain.Models.Virtual.Details
private typealias Entry = Domain.Models.Virtual.Details

public extension Data.DataSources {
    final class MangaLocalDataSource {
        internal init() {}
    }
}

internal extension MangaLocalDataSource {
    func getMangaDetails(entry: Domain.Models.Virtual.Entry) -> AnyPublisher<[Domain.Models.Virtual.Details], Error> {
        return ValueObservation.tracking { [weak self] db -> [Details] in
            return []
        }
        .publisher(in: DatabaseProvider.shared.writer, scheduling: .immediate)
        .eraseToAnyPublisher()
    }
}

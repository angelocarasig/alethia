//
//  RepositoryFactory.swift
//  Composition
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain
import Data

/// Factory for creating repository instances
internal final class RepositoryFactory {
    private let database: DatabaseConfiguration
    
    init(database: DatabaseConfiguration? = nil) {
        self.database = database ?? DatabaseConfiguration.shared
    }
    
    lazy var hostRepository: HostRepository = {
        HostRepositoryImpl()
    }()
}
